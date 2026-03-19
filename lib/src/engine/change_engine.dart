import 'models.dart';
import 'scoring.dart';

class SinglePlanResult {
  const SinglePlanResult({
    required this.primaryPlan,
    required this.alternativePlans,
    required this.modeUsed,
  });

  final ChangePlan primaryPlan;
  final List<ChangePlan> alternativePlans;
  final EngineMode modeUsed;
}

class ChangeEngine {
  const ChangeEngine({required this.denomSet, required this.weights});

  final DenominationSet denomSet;
  final ScoreWeights weights;

  SinglePlanResult solvePassenger({
    required PassengerDue due,
    required PocketInventory pocketBeforePayout,
    required EngineConfig config,
  }) {
    if (due.changeDueMinor < 0) {
      final List<ChangeItem> completionItems = _buildUnboundedItems(
        due.changeDueMinor.abs(),
      );
      return SinglePlanResult(
        primaryPlan: ChangePlan(
          passengerId: due.id,
          status: ChangeStatus.underpaid,
          dueMinor: due.dueMinor,
          paidMinor: due.paidMinor,
          changeDueMinor: due.changeDueMinor,
          items: completionItems,
          roundingDeltaMinor: 0,
          note: 'التكملة محسوبة بنفس فئات العملة المتاحة.',
        ),
        alternativePlans: const <ChangePlan>[],
        modeUsed: EngineMode.fastGreedy,
      );
    }

    if (due.changeDueMinor == 0) {
      return SinglePlanResult(
        primaryPlan: ChangePlan(
          passengerId: due.id,
          status: ChangeStatus.exact,
          dueMinor: due.dueMinor,
          paidMinor: due.paidMinor,
          changeDueMinor: 0,
          items: const <ChangeItem>[],
          roundingDeltaMinor: 0,
        ),
        alternativePlans: const <ChangePlan>[],
        modeUsed: EngineMode.fastGreedy,
      );
    }

    final List<ChangeItem>? greedyItems = greedyBounded(
      targetMinor: due.changeDueMinor,
      pocket: pocketBeforePayout,
    );
    if (greedyItems != null) {
      final List<ChangePlan> candidatePlans = buildTopKPlans(
        due: due,
        pocketBeforePayout: pocketBeforePayout,
        topK: config.topKPlansPerPassenger,
      );
      final ChangePlan primaryPlan = candidatePlans.isNotEmpty
          ? candidatePlans.first
          : _planFromItems(due: due, items: greedyItems);
      final List<ChangePlan> alternativePlans = candidatePlans.length <= 1
          ? const <ChangePlan>[]
          : candidatePlans.skip(1).toList(growable: false);

      return SinglePlanResult(
        primaryPlan: primaryPlan,
        alternativePlans: alternativePlans,
        modeUsed: EngineMode.fastGreedy,
      );
    }

    final ChangePlan? bestPlan = solveExactBestPlan(
      due: due,
      pocketBeforePayout: pocketBeforePayout,
    );
    if (bestPlan == null) {
      return SinglePlanResult(
        primaryPlan: ChangePlan(
          passengerId: due.id,
          status: ChangeStatus.infeasible,
          dueMinor: due.dueMinor,
          paidMinor: due.paidMinor,
          changeDueMinor: due.changeDueMinor,
          items: const <ChangeItem>[],
          roundingDeltaMinor: 0,
          note: 'اطلب ورقة أصغر أو سجّلها كتسوية مفتوحة.',
        ),
        alternativePlans: const <ChangePlan>[],
        modeUsed: EngineMode.smartDp,
      );
    }

    final List<ChangePlan> candidatePlans = buildTopKPlans(
      due: due,
      pocketBeforePayout: pocketBeforePayout,
      topK: config.topKPlansPerPassenger,
    );

    return SinglePlanResult(
      primaryPlan: candidatePlans.isEmpty ? bestPlan : candidatePlans.first,
      alternativePlans: candidatePlans.length <= 1
          ? const <ChangePlan>[]
          : candidatePlans.skip(1).toList(growable: false),
      modeUsed: EngineMode.smartDp,
    );
  }

  List<ChangePlan> buildTopKPlans({
    required PassengerDue due,
    required PocketInventory pocketBeforePayout,
    required int topK,
  }) {
    if (due.changeDueMinor <= 0) {
      return const <ChangePlan>[];
    }

    final List<_PlanCandidate> candidates = <_PlanCandidate>[];
    final List<int> denominations = denomSet.denomsDesc;
    final int targetMinor = due.changeDueMinor;

    void search(int index, int remainingMinor, Map<int, int> currentItems) {
      if (remainingMinor == 0) {
        final List<ChangeItem> items = _toItems(currentItems);
        final int score = scorePlan(
          items: items,
          pocketBeforePayout: pocketBeforePayout,
          w: weights,
        );
        candidates.add(_PlanCandidate(items: items, score: score));
        return;
      }

      if (index >= denominations.length) {
        return;
      }

      final int denominationMinor = denominations[index];
      final int available = pocketBeforePayout.countOf(denominationMinor);
      final int maxCount = _min(remainingMinor ~/ denominationMinor, available);

      for (int count = maxCount; count >= 0; count--) {
        if (count > 0) {
          currentItems[denominationMinor] = count;
        } else {
          currentItems.remove(denominationMinor);
        }
        search(
          index + 1,
          remainingMinor - (count * denominationMinor),
          currentItems,
        );
      }
    }

    search(0, targetMinor, <int, int>{});
    candidates.sort(_compareCandidates);

    final List<_PlanCandidate> uniqueCandidates = <_PlanCandidate>[];
    final Set<String> seen = <String>{};
    for (final _PlanCandidate candidate in candidates) {
      final String key = candidate.items
          .map((ChangeItem item) => '${item.denomMinor}:${item.count}')
          .join('|');
      if (seen.add(key)) {
        uniqueCandidates.add(candidate);
      }
      if (uniqueCandidates.length >= topK) {
        break;
      }
    }

    return uniqueCandidates
        .map((candidate) => _planFromItems(due: due, items: candidate.items))
        .toList(growable: false);
  }

  ChangePlan? solveExactBestPlan({
    required PassengerDue due,
    required PocketInventory pocketBeforePayout,
  }) {
    if (due.changeDueMinor <= 0) {
      return null;
    }

    final int scale = denomSet.gcd;
    final int target = due.changeDueMinor ~/ scale;
    final List<_DpState?> dp = List<_DpState?>.filled(target + 1, null);
    dp[0] = const _DpState(<int, int>{});

    for (final int denominationMinor in denomSet.denomsDesc) {
      final int scaledDenomination = denominationMinor ~/ scale;
      final int usableCount = _min(
        pocketBeforePayout.countOf(denominationMinor),
        due.changeDueMinor ~/ denominationMinor,
      );

      for (int copy = 0; copy < usableCount; copy++) {
        for (int amount = target; amount >= scaledDenomination; amount--) {
          final _DpState? previous = dp[amount - scaledDenomination];
          if (previous == null) {
            continue;
          }

          final Map<int, int> candidateMap = Map<int, int>.from(previous.items);
          candidateMap.update(
            denominationMinor,
            (int value) => value + 1,
            ifAbsent: () => 1,
          );

          final List<ChangeItem> candidateItems = _toItems(candidateMap);
          final int candidateScore = scorePlan(
            items: candidateItems,
            pocketBeforePayout: pocketBeforePayout,
            w: weights,
          );
          final _DpState candidateState = _DpState(candidateMap);
          final _DpState? current = dp[amount];
          if (current == null ||
              _isBetterState(
                candidateState: candidateState,
                currentState: current,
                candidateScore: candidateScore,
                currentScore: scorePlan(
                  items: _toItems(current.items),
                  pocketBeforePayout: pocketBeforePayout,
                  w: weights,
                ),
              )) {
            dp[amount] = candidateState;
          }
        }
      }
    }

    final _DpState? solvedState = dp[target];
    if (solvedState == null) {
      return null;
    }

    return _planFromItems(due: due, items: _toItems(solvedState.items));
  }

  List<ChangeItem>? greedyBounded({
    required int targetMinor,
    required PocketInventory pocket,
  }) {
    int remainingMinor = targetMinor;
    final Map<int, int> items = <int, int>{};

    for (final int denominationMinor in denomSet.denomsDesc) {
      final int count = _min(
        pocket.countOf(denominationMinor),
        remainingMinor ~/ denominationMinor,
      );
      if (count <= 0) {
        continue;
      }

      items[denominationMinor] = count;
      remainingMinor -= count * denominationMinor;
    }

    if (remainingMinor != 0) {
      return null;
    }

    return _toItems(items);
  }

  List<ChangeItem> _buildUnboundedItems(int targetMinor) {
    int remainingMinor = targetMinor;
    final Map<int, int> items = <int, int>{};

    for (final int denominationMinor in denomSet.denomsDesc) {
      final int count = remainingMinor ~/ denominationMinor;
      if (count <= 0) {
        continue;
      }

      items[denominationMinor] = count;
      remainingMinor -= count * denominationMinor;
    }

    if (remainingMinor != 0) {
      return const <ChangeItem>[];
    }

    return _toItems(items);
  }

  ChangePlan _planFromItems({
    required PassengerDue due,
    required List<ChangeItem> items,
  }) {
    return ChangePlan(
      passengerId: due.id,
      status: ChangeStatus.exact,
      dueMinor: due.dueMinor,
      paidMinor: due.paidMinor,
      changeDueMinor: due.changeDueMinor,
      items: items,
      roundingDeltaMinor: 0,
    );
  }

  bool _isBetterState({
    required _DpState candidateState,
    required _DpState currentState,
    required int candidateScore,
    required int currentScore,
  }) {
    if (candidateScore != currentScore) {
      return candidateScore < currentScore;
    }

    final int candidateNoteCount = candidateState.items.values.fold<int>(
      0,
      (int sum, int count) => sum + count,
    );
    final int currentNoteCount = currentState.items.values.fold<int>(
      0,
      (int sum, int count) => sum + count,
    );
    if (candidateNoteCount != currentNoteCount) {
      return candidateNoteCount < currentNoteCount;
    }

    return _signatureFor(
          candidateState.items,
        ).compareTo(_signatureFor(currentState.items)) <
        0;
  }

  int _compareCandidates(_PlanCandidate a, _PlanCandidate b) {
    if (a.score != b.score) {
      return a.score.compareTo(b.score);
    }

    final int itemCountCompare = a.totalItems.compareTo(b.totalItems);
    if (itemCountCompare != 0) {
      return itemCountCompare;
    }

    return _signatureForMap(a.items).compareTo(_signatureForMap(b.items));
  }

  List<ChangeItem> _toItems(Map<int, int> items) {
    final List<int> denominations = items.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return denominations
        .map((int denominationMinor) {
          return ChangeItem(denominationMinor, items[denominationMinor]!);
        })
        .toList(growable: false);
  }

  String _signatureFor(Map<int, int> items) {
    final List<int> denominations = items.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return denominations
        .map(
          (int denominationMinor) =>
              '$denominationMinor:${items[denominationMinor]}',
        )
        .join('|');
  }

  String _signatureForMap(List<ChangeItem> items) {
    return items
        .map((ChangeItem item) => '${item.denomMinor}:${item.count}')
        .join('|');
  }
}

class _DpState {
  const _DpState(this.items);

  final Map<int, int> items;
}

class _PlanCandidate {
  const _PlanCandidate({required this.items, required this.score});

  final List<ChangeItem> items;
  final int score;

  int get totalItems {
    return items.fold<int>(0, (int sum, ChangeItem item) => sum + item.count);
  }
}

int _min(int a, int b) => a < b ? a : b;
