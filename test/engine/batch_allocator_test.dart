import 'package:flutter_test/flutter_test.dart';
import 'package:ogra/engine/engine_facade.dart';
import 'package:ogra/engine/models.dart';
import 'package:ogra/engine/scoring.dart';

void main() {
  final ChangeDistributionEngine engine = ChangeDistributionEngine(
    denomSet: DenominationSet.egpWithHalf(),
    weights: ScoreWeights.defaultsEgp(),
  );

  test(
    'batch allocation uses incoming payments before distributing change',
    () async {
      final BatchAllocationResult result = await engine.allocateBatch(
        farePerRiderMinor: 500,
        payments: <PassengerPayment>[
          PassengerPayment.fromDenominations(
            id: 'a',
            riders: 1,
            receivedDenominationsMinor: <int>[1000],
          ),
          PassengerPayment.fromDenominations(
            id: 'b',
            riders: 1,
            receivedDenominationsMinor: <int>[500],
          ),
        ],
        pocketBefore: PocketInventory.initial(),
        config: EngineConfig.mppDefaults(),
        startedAt: DateTime.now(),
      );

      final ChangePlan planA = result.plans.firstWhere(
        (ChangePlan plan) => plan.passengerId == 'a',
      );
      expect(planA.items.single.denomMinor, 500);
      expect(result.pocketAfter.countOf(500), 0);
    },
  );

  test(
    'batch allocation returns feasible plans for multiple passengers',
    () async {
      final PocketInventory pocket = PocketInventory(<int, int>{
        20000: 0,
        10000: 0,
        5000: 0,
        2000: 1,
        1000: 2,
        500: 2,
        100: 0,
        50: 0,
      });

      final BatchAllocationResult result = await engine.allocateBatch(
        farePerRiderMinor: 1500,
        payments: <PassengerPayment>[
          PassengerPayment.fromDenominations(
            id: 'a',
            riders: 2,
            receivedDenominationsMinor: <int>[5000],
          ),
          PassengerPayment.fromDenominations(
            id: 'b',
            riders: 1,
            receivedDenominationsMinor: <int>[2000],
          ),
        ],
        pocketBefore: pocket,
        config: EngineConfig.mppDefaults(),
        startedAt: DateTime.now(),
      );

      expect(
        result.plans.every(
          (ChangePlan plan) => plan.status != ChangeStatus.infeasible,
        ),
        isTrue,
      );
    },
  );

  test(
    'batch allocator falls back when search budget is exhausted immediately',
    () async {
      final BatchAllocationResult result = await engine.allocateBatch(
        farePerRiderMinor: 500,
        payments: <PassengerPayment>[
          PassengerPayment.fromDenominations(
            id: 'a',
            riders: 1,
            receivedDenominationsMinor: <int>[1000],
          ),
          PassengerPayment.fromDenominations(
            id: 'b',
            riders: 1,
            receivedDenominationsMinor: <int>[1000],
          ),
        ],
        pocketBefore: PocketInventory.initial(),
        config: EngineConfig.mppDefaults().copyWith(
          searchDepthLimit: 0,
          timeBudgetMs: 0,
        ),
        startedAt: DateTime.now(),
      );

      expect(result.modeUsed, EngineMode.fallbackGreedy);
    },
  );
}
