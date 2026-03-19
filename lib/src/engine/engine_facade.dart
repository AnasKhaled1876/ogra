import 'batch_allocator.dart';
import 'change_engine.dart';
import 'models.dart';
import 'scoring.dart';

class ChangeDistributionEngine {
  const ChangeDistributionEngine({
    required this.denomSet,
    required this.weights,
  });

  final DenominationSet denomSet;
  final ScoreWeights weights;

  ChangeEngine get _changeEngine =>
      ChangeEngine(denomSet: denomSet, weights: weights);

  BatchAllocator get _batchAllocator => BatchAllocator(
    denomSet: denomSet,
    weights: weights,
    changeEngine: _changeEngine,
  );

  List<PassengerDue> computeDues({
    required Money farePerRiderMinor,
    required List<PassengerPayment> payments,
  }) {
    return payments
        .map((PassengerPayment payment) {
          final int dueMinor = farePerRiderMinor * payment.riders;
          return PassengerDue(
            id: payment.id,
            riders: payment.riders,
            dueMinor: dueMinor,
            paidMinor: payment.paidMinor,
            changeDueMinor: payment.paidMinor - dueMinor,
          );
        })
        .toList(growable: false);
  }

  BatchAllocationResult previewSingle({
    required Money farePerRiderMinor,
    required PassengerPayment payment,
    required PocketInventory pocketBefore,
    required EngineConfig config,
    required DateTime startedAt,
  }) {
    final Stopwatch stopwatch = Stopwatch()..start();
    final List<PassengerDue> dues = computeDues(
      farePerRiderMinor: farePerRiderMinor,
      payments: <PassengerPayment>[payment],
    );
    final PocketInventory pocketAfterPayments = pocketBefore
        .addPaymentDenominations(payment.receivedDenominationsMinor);
    final SinglePlanResult result = _changeEngine.solvePassenger(
      due: dues.first,
      pocketBeforePayout: pocketAfterPayments,
      config: config,
    );

    final PocketInventory pocketAfter =
        _planConsumesPocket(result.primaryPlan) &&
            pocketAfterPayments.canPay(result.primaryPlan.items)
        ? pocketAfterPayments.applyChange(result.primaryPlan.items)
        : pocketAfterPayments;

    stopwatch.stop();
    return BatchAllocationResult(
      modeUsed: result.modeUsed,
      plans: <ChangePlan>[result.primaryPlan, ...result.alternativePlans],
      pocketAfter: pocketAfter,
      warnings: const <String>[],
      latencyMs: stopwatch.elapsedMilliseconds,
    );
  }

  BatchAllocationResult previewDirectSettlement({
    required Money dueMinor,
    required List<Denom> receivedDenominationsMinor,
    required PocketInventory pocketBefore,
    required EngineConfig config,
    required DateTime startedAt,
  }) {
    final PassengerPayment payment = PassengerPayment.fromDenominations(
      id: 'settlement',
      riders: 1,
      receivedDenominationsMinor: receivedDenominationsMinor,
    );
    final PassengerDue due = PassengerDue(
      id: 'settlement',
      riders: 1,
      dueMinor: dueMinor,
      paidMinor: payment.paidMinor,
      changeDueMinor: payment.paidMinor - dueMinor,
    );

    return _previewDue(
      due: due,
      receivedDenominationsMinor: receivedDenominationsMinor,
      pocketBefore: pocketBefore,
      config: config,
    );
  }

  BatchAllocationResult previewReturnOnly({
    required Money returnMinor,
    required PocketInventory pocketBefore,
    required EngineConfig config,
    required DateTime startedAt,
  }) {
    final PassengerDue due = PassengerDue(
      id: 'settlement_return',
      riders: 1,
      dueMinor: 0,
      paidMinor: returnMinor,
      changeDueMinor: returnMinor,
    );

    return _previewDue(
      due: due,
      receivedDenominationsMinor: const <Denom>[],
      pocketBefore: pocketBefore,
      config: config,
    );
  }

  Future<BatchAllocationResult> allocateBatch({
    required Money farePerRiderMinor,
    required List<PassengerPayment> payments,
    required PocketInventory pocketBefore,
    required EngineConfig config,
    required DateTime startedAt,
  }) async {
    final List<PassengerDue> dues = computeDues(
      farePerRiderMinor: farePerRiderMinor,
      payments: payments,
    );

    if (payments.length <= 1) {
      return previewSingle(
        farePerRiderMinor: farePerRiderMinor,
        payment: payments.first,
        pocketBefore: pocketBefore,
        config: config,
        startedAt: startedAt,
      );
    }

    return _batchAllocator.allocate(
      dues: dues,
      payments: payments,
      pocketBefore: pocketBefore,
      config: config,
    );
  }

  BatchAllocationResult previewGroupedReturns({
    required List<PassengerDue> returnDues,
    required PocketInventory pocketBefore,
    required EngineConfig config,
    required DateTime startedAt,
  }) {
    return _batchAllocator.allocate(
      dues: returnDues,
      payments: const <PassengerPayment>[],
      pocketBefore: pocketBefore,
      config: config,
    );
  }

  bool _planConsumesPocket(ChangePlan plan) {
    return plan.status != ChangeStatus.underpaid &&
        plan.status != ChangeStatus.infeasible &&
        plan.items.isNotEmpty;
  }

  BatchAllocationResult _previewDue({
    required PassengerDue due,
    required List<Denom> receivedDenominationsMinor,
    required PocketInventory pocketBefore,
    required EngineConfig config,
  }) {
    final Stopwatch stopwatch = Stopwatch()..start();
    final PocketInventory pocketAfterPayments =
        receivedDenominationsMinor.isEmpty
        ? pocketBefore
        : pocketBefore.addPaymentDenominations(receivedDenominationsMinor);
    final SinglePlanResult result = _changeEngine.solvePassenger(
      due: due,
      pocketBeforePayout: pocketAfterPayments,
      config: config,
    );

    final PocketInventory pocketAfter =
        _planConsumesPocket(result.primaryPlan) &&
            pocketAfterPayments.canPay(result.primaryPlan.items)
        ? pocketAfterPayments.applyChange(result.primaryPlan.items)
        : pocketAfterPayments;

    stopwatch.stop();
    return BatchAllocationResult(
      modeUsed: result.modeUsed,
      plans: <ChangePlan>[result.primaryPlan, ...result.alternativePlans],
      pocketAfter: pocketAfter,
      warnings: const <String>[],
      latencyMs: stopwatch.elapsedMilliseconds,
    );
  }
}
