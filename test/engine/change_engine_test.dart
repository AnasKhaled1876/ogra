import 'package:flutter_test/flutter_test.dart';
import 'package:ogra/engine/change_engine.dart';
import 'package:ogra/engine/engine_facade.dart';
import 'package:ogra/engine/models.dart';
import 'package:ogra/engine/scoring.dart';

void main() {
  final DenominationSet denomSet = DenominationSet.egpWithHalf();
  final ScoreWeights weights = ScoreWeights.defaultsEgp();
  final ChangeEngine changeEngine = ChangeEngine(
    denomSet: denomSet,
    weights: weights,
  );
  final ChangeDistributionEngine facade = ChangeDistributionEngine(
    denomSet: denomSet,
    weights: weights,
  );

  test('computeDues returns correct due and change per passenger', () {
    final List<PassengerDue> dues = facade.computeDues(
      farePerRiderMinor: 1500,
      payments: <PassengerPayment>[
        PassengerPayment.fromDenominations(
          id: 'a',
          riders: 2,
          receivedDenominationsMinor: <int>[5000],
        ),
      ],
    );

    expect(dues.single.dueMinor, 3000);
    expect(dues.single.changeDueMinor, 2000);
  });

  test(
    'greedy bounded returns null when bounded inventory makes greedy fail',
    () {
      final PocketInventory pocket = PocketInventory(<int, int>{
        20000: 0,
        10000: 0,
        5000: 1,
        2000: 4,
        1000: 0,
        500: 0,
        100: 0,
        50: 0,
      });

      final List<ChangeItem>? result = changeEngine.greedyBounded(
        targetMinor: 8000,
        pocket: pocket,
      );

      expect(result, isNull);
    },
  );

  test('smart dp returns feasible exact plan when greedy path fails', () {
    final PassengerDue due = PassengerDue(
      id: 'a',
      riders: 1,
      dueMinor: 0,
      paidMinor: 8000,
      changeDueMinor: 8000,
    );
    final PocketInventory pocket = PocketInventory(<int, int>{
      20000: 0,
      10000: 0,
      5000: 1,
      2000: 4,
      1000: 0,
      500: 0,
      100: 0,
      50: 0,
    });

    final ChangePlan? plan = changeEngine.solveExactBestPlan(
      due: due,
      pocketBeforePayout: pocket,
    );

    expect(plan, isNotNull);
    expect(plan!.items.single.denomMinor, 2000);
    expect(plan.items.single.count, 4);
  });

  test('balanced scoring prefers fewer notes when both plans are feasible', () {
    final PassengerDue due = PassengerDue(
      id: 'a',
      riders: 1,
      dueMinor: 0,
      paidMinor: 2000,
      changeDueMinor: 2000,
    );
    final PocketInventory pocket = PocketInventory(<int, int>{
      20000: 0,
      10000: 0,
      5000: 0,
      2000: 1,
      1000: 2,
      500: 0,
      100: 0,
      50: 0,
    });

    final List<ChangePlan> candidates = changeEngine.buildTopKPlans(
      due: due,
      pocketBeforePayout: pocket,
      topK: 2,
    );

    expect(candidates.first.items.single.denomMinor, 2000);
  });

  test('engine supports 0.5 denomination in exact plans', () {
    final PassengerDue due = PassengerDue(
      id: 'a',
      riders: 1,
      dueMinor: 0,
      paidMinor: 150,
      changeDueMinor: 150,
    );
    final PocketInventory pocket = PocketInventory(<int, int>{
      20000: 0,
      10000: 0,
      5000: 0,
      2000: 0,
      1000: 0,
      500: 0,
      100: 1,
      50: 1,
    });

    final ChangePlan? plan = changeEngine.solveExactBestPlan(
      due: due,
      pocketBeforePayout: pocket,
    );

    expect(plan, isNotNull);
    expect(plan!.items.length, 2);
    expect(plan.items.first.denomMinor, 100);
    expect(plan.items.last.denomMinor, 50);
  });

  test('underpaid plans carry exact completion denominations', () {
    final EngineConfig config = EngineConfig.mppDefaults();
    final SinglePlanResult result = changeEngine.solvePassenger(
      due: const PassengerDue(
        id: 'a',
        riders: 1,
        dueMinor: 2500,
        paidMinor: 1500,
        changeDueMinor: -1000,
      ),
      pocketBeforePayout: PocketInventory.initial(),
      config: config,
    );

    expect(result.primaryPlan.status, ChangeStatus.underpaid);
    expect(result.primaryPlan.items.single.denomMinor, 1000);
    expect(result.primaryPlan.items.single.count, 1);
  });

  test('direct settlement preview handles exact completion', () {
    final BatchAllocationResult result = facade.previewDirectSettlement(
      dueMinor: 1000,
      receivedDenominationsMinor: const <int>[1000],
      pocketBefore: PocketInventory.initial(),
      config: EngineConfig.mppDefaults(),
      startedAt: DateTime(2026, 3, 18),
    );

    expect(result.plans.first.status, ChangeStatus.exact);
    expect(result.plans.first.changeDueMinor, 0);
    expect(result.plans.first.items, isEmpty);
    expect(result.pocketAfter.countOf(1000), 1);
  });

  test('direct settlement preview converts overpayment into return change', () {
    final BatchAllocationResult result = facade.previewDirectSettlement(
      dueMinor: 1000,
      receivedDenominationsMinor: const <int>[2000],
      pocketBefore: const PocketInventory(<int, int>{
        20000: 0,
        10000: 0,
        5000: 0,
        2000: 0,
        1000: 0,
        500: 2,
        100: 0,
        50: 0,
      }),
      config: EngineConfig.mppDefaults(),
      startedAt: DateTime(2026, 3, 18),
    );

    expect(result.plans.first.status, ChangeStatus.exact);
    expect(result.plans.first.changeDueMinor, 1000);
    expect(result.plans.first.items.single.denomMinor, 500);
    expect(result.plans.first.items.single.count, 2);
  });

  test('return-only preview resolves when pocket can settle now', () {
    final BatchAllocationResult result = facade.previewReturnOnly(
      returnMinor: 1000,
      pocketBefore: const PocketInventory(<int, int>{
        20000: 0,
        10000: 0,
        5000: 0,
        2000: 0,
        1000: 1,
        500: 0,
        100: 0,
        50: 0,
      }),
      config: EngineConfig.mppDefaults(),
      startedAt: DateTime(2026, 3, 18),
    );

    expect(result.plans.first.status, ChangeStatus.exact);
    expect(result.plans.first.items.single.denomMinor, 1000);
    expect(result.pocketAfter.countOf(1000), 0);
  });

  test(
    'return-only preview stays infeasible when pocket cannot settle now',
    () {
      final BatchAllocationResult result = facade.previewReturnOnly(
        returnMinor: 1000,
        pocketBefore: const PocketInventory(<int, int>{
          20000: 0,
          10000: 0,
          5000: 1,
          2000: 0,
          1000: 0,
          500: 0,
          100: 0,
          50: 0,
        }),
        config: EngineConfig.mppDefaults(),
        startedAt: DateTime(2026, 3, 18),
      );

      expect(result.plans.first.status, ChangeStatus.infeasible);
      expect(result.plans.first.items, isEmpty);
      expect(result.pocketAfter.countOf(5000), 1);
    },
  );

  test('solvePassenger is deterministic for repeated runs', () {
    final PassengerDue due = PassengerDue(
      id: 'a',
      riders: 1,
      dueMinor: 0,
      paidMinor: 2000,
      changeDueMinor: 2000,
    );
    final PocketInventory pocket = PocketInventory(<int, int>{
      20000: 0,
      10000: 0,
      5000: 0,
      2000: 1,
      1000: 2,
      500: 0,
      100: 0,
      50: 0,
    });
    final EngineConfig config = EngineConfig.mppDefaults();

    final SinglePlanResult first = changeEngine.solvePassenger(
      due: due,
      pocketBeforePayout: pocket,
      config: config,
    );
    final SinglePlanResult second = changeEngine.solvePassenger(
      due: due,
      pocketBeforePayout: pocket,
      config: config,
    );

    expect(
      first.primaryPlan.items.map((ChangeItem item) => item.denomMinor),
      orderedEquals(
        second.primaryPlan.items.map((ChangeItem item) => item.denomMinor),
      ),
    );
  });
}
