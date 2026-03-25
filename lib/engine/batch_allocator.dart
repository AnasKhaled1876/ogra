import 'change_engine.dart';
import 'models.dart';
import 'scoring.dart';

class BatchAllocator {
  const BatchAllocator({
    required this.denomSet,
    required this.weights,
    required this.changeEngine,
  });

  final DenominationSet denomSet;
  final ScoreWeights weights;
  final ChangeEngine changeEngine;

  BatchAllocationResult allocate({
    required List<PassengerDue> dues,
    required List<PassengerPayment> payments,
    required PocketInventory pocketBefore,
    required EngineConfig config,
  }) {
    final Stopwatch stopwatch = Stopwatch()..start();
    final PocketInventory pocketAfterPayments = _addIncomingPayments(
      pocketBefore: pocketBefore,
      payments: payments,
    );

    final Map<String, List<ChangePlan>> candidatesByPassengerId =
        <String, List<ChangePlan>>{};
    for (final PassengerDue due in dues) {
      if (due.changeDueMinor <= 0) {
        candidatesByPassengerId[due.id] = <ChangePlan>[
          changeEngine
              .solvePassenger(
                due: due,
                pocketBeforePayout: pocketAfterPayments,
                config: config,
              )
              .primaryPlan,
        ];
        continue;
      }

      final List<ChangePlan> candidates = changeEngine.buildTopKPlans(
        due: due,
        pocketBeforePayout: pocketAfterPayments,
        topK: config.topKPlansPerPassenger,
      );
      candidatesByPassengerId[due.id] = candidates.isEmpty
          ? <ChangePlan>[
              ChangePlan(
                passengerId: due.id,
                status: ChangeStatus.infeasible,
                dueMinor: due.dueMinor,
                paidMinor: due.paidMinor,
                changeDueMinor: due.changeDueMinor,
                items: const <ChangeItem>[],
                roundingDeltaMinor: 0,
                note: 'اطلب ورقة أصغر أو سجّلها كتسوية مفتوحة.',
              ),
            ]
          : candidates;
    }

    final List<PassengerDue> orderedDues = dues.toList()
      ..sort((PassengerDue a, PassengerDue b) {
        final int candidatesCompare =
            (candidatesByPassengerId[a.id]?.length ?? 0).compareTo(
              candidatesByPassengerId[b.id]?.length ?? 0,
            );
        if (candidatesCompare != 0) {
          return candidatesCompare;
        }
        return b.changeDueMinor.compareTo(a.changeDueMinor);
      });

    _SearchState? bestState;
    bool timedOut = false;

    void search({
      required int index,
      required PocketInventory pocketCurrent,
      required List<ChangePlan> chosenPlans,
      required int score,
      required int infeasibleCount,
    }) {
      if (stopwatch.elapsedMilliseconds > config.timeBudgetMs ||
          chosenPlans.length > config.searchDepthLimit) {
        timedOut = true;
        return;
      }

      if (index >= orderedDues.length) {
        final _SearchState candidateState = _SearchState(
          chosenPlans: List<ChangePlan>.from(chosenPlans),
          pocketAfter: pocketCurrent,
          score: score,
          infeasibleCount: infeasibleCount,
        );
        if (bestState == null || candidateState.isBetterThan(bestState!)) {
          bestState = candidateState;
        }
        return;
      }

      final PassengerDue due = orderedDues[index];
      final List<ChangePlan> candidates = candidatesByPassengerId[due.id]!;
      for (final ChangePlan candidate in candidates) {
        if (candidate.status == ChangeStatus.infeasible) {
          chosenPlans.add(candidate);
          search(
            index: index + 1,
            pocketCurrent: pocketCurrent,
            chosenPlans: chosenPlans,
            score: score + 100000,
            infeasibleCount: infeasibleCount + 1,
          );
          chosenPlans.removeLast();
          continue;
        }

        if (_planConsumesPocket(candidate) &&
            !pocketCurrent.canPay(candidate.items)) {
          continue;
        }

        final PocketInventory nextPocket = _planConsumesPocket(candidate)
            ? pocketCurrent.applyChange(candidate.items)
            : pocketCurrent;
        chosenPlans.add(candidate);
        search(
          index: index + 1,
          pocketCurrent: nextPocket,
          chosenPlans: chosenPlans,
          score:
              score +
              (_planConsumesPocket(candidate)
                  ? scorePlan(
                      items: candidate.items,
                      pocketBeforePayout: pocketCurrent,
                      w: weights,
                    )
                  : 0),
          infeasibleCount: infeasibleCount,
        );
        chosenPlans.removeLast();
      }
    }

    search(
      index: 0,
      pocketCurrent: pocketAfterPayments,
      chosenPlans: <ChangePlan>[],
      score: 0,
      infeasibleCount: 0,
    );

    if (bestState == null) {
      final _SearchState fallbackState = _runSequentialFallback(
        dues: dues,
        pocketAfterPayments: pocketAfterPayments,
        config: config,
      );
      stopwatch.stop();
      return BatchAllocationResult(
        modeUsed: EngineMode.fallbackGreedy,
        plans: fallbackState.chosenPlans,
        pocketAfter: fallbackState.pocketAfter,
        warnings: <String>[
          if (timedOut) 'تم استخدام التسوية المتتابعة بعد انتهاء مهلة البحث.',
        ],
        latencyMs: stopwatch.elapsedMilliseconds,
      );
    }

    final Map<String, ChangePlan> planByPassengerId = <String, ChangePlan>{
      for (final ChangePlan plan in bestState!.chosenPlans)
        plan.passengerId: plan,
    };
    final List<ChangePlan> orderedPlans = dues
        .map((PassengerDue due) => planByPassengerId[due.id]!)
        .toList(growable: false);

    stopwatch.stop();
    return BatchAllocationResult(
      modeUsed: EngineMode.batchSearch,
      plans: orderedPlans,
      pocketAfter: bestState!.pocketAfter,
      warnings: <String>[
        if (timedOut) 'تم إيقاف البحث عند حد الوقت واستخدام أفضل نتيجة متاحة.',
      ],
      latencyMs: stopwatch.elapsedMilliseconds,
    );
  }

  PocketInventory _addIncomingPayments({
    required PocketInventory pocketBefore,
    required List<PassengerPayment> payments,
  }) {
    PocketInventory nextPocket = pocketBefore;
    for (final PassengerPayment payment in payments) {
      final List<int> denominations = payment.receivedDenominationsMinor.isEmpty
          ? _fallbackBreakdown(payment.paidMinor)
          : payment.receivedDenominationsMinor;
      nextPocket = nextPocket.addPaymentDenominations(denominations);
    }
    return nextPocket;
  }

  List<int> _fallbackBreakdown(int paidMinor) {
    int remainingMinor = paidMinor;
    final List<int> items = <int>[];

    for (final int denominationMinor in denomSet.denomsDesc) {
      while (remainingMinor >= denominationMinor) {
        items.add(denominationMinor);
        remainingMinor -= denominationMinor;
      }
    }

    if (remainingMinor != 0) {
      return <int>[paidMinor];
    }

    return items;
  }

  _SearchState _runSequentialFallback({
    required List<PassengerDue> dues,
    required PocketInventory pocketAfterPayments,
    required EngineConfig config,
  }) {
    PocketInventory pocketCurrent = pocketAfterPayments;
    final List<ChangePlan> plans = <ChangePlan>[];

    for (final PassengerDue due in dues) {
      final SinglePlanResult result = changeEngine.solvePassenger(
        due: due,
        pocketBeforePayout: pocketCurrent,
        config: config,
      );
      plans.add(result.primaryPlan);
      if (_planConsumesPocket(result.primaryPlan) &&
          pocketCurrent.canPay(result.primaryPlan.items)) {
        pocketCurrent = pocketCurrent.applyChange(result.primaryPlan.items);
      }
    }

    return _SearchState(
      chosenPlans: plans,
      pocketAfter: pocketCurrent,
      score: 0,
      infeasibleCount: plans
          .where((ChangePlan plan) => plan.status == ChangeStatus.infeasible)
          .length,
    );
  }

  bool _planConsumesPocket(ChangePlan plan) {
    return plan.status != ChangeStatus.underpaid &&
        plan.status != ChangeStatus.infeasible &&
        plan.items.isNotEmpty;
  }
}

class _SearchState {
  const _SearchState({
    required this.chosenPlans,
    required this.pocketAfter,
    required this.score,
    required this.infeasibleCount,
  });

  final List<ChangePlan> chosenPlans;
  final PocketInventory pocketAfter;
  final int score;
  final int infeasibleCount;

  bool isBetterThan(_SearchState other) {
    if (infeasibleCount != other.infeasibleCount) {
      return infeasibleCount < other.infeasibleCount;
    }
    return score < other.score;
  }
}
