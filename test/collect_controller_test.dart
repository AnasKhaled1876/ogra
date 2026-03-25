import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ogra/engine/models.dart';
import 'package:ogra/features/collect/application/collect_controller.dart';
import 'package:ogra/features/collect/application/open_settlement_view.dart';
import 'package:ogra/features/collect/domain/pending_commit.dart';
import 'package:ogra/features/collect/domain/settlement_models.dart';
import 'package:ogra/features/collect/domain/transaction_record.dart';
import 'package:ogra/features/pocket/application/pocket_controller.dart';
import 'package:ogra/features/settings/application/settings_controller.dart';

String? _hiveTestPath;

Future<void> _initHive() async {
  _hiveTestPath ??= Directory.systemTemp
      .createTempSync('ogra_collect_controller_test_')
      .path;
  Hive.init(_hiveTestPath!);
  if (!Hive.isBoxOpen('app_settings')) {
    await Hive.openBox<Map>('app_settings');
  }
  if (!Hive.isBoxOpen('pocket_state')) {
    await Hive.openBox<Map>('pocket_state');
  }
  if (!Hive.isBoxOpen('transactions')) {
    await Hive.openBox<Map>('transactions');
  }
  if (!Hive.isBoxOpen('pending_commit')) {
    await Hive.openBox<Map>('pending_commit');
  }
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  setUpAll(() async {
    await _initHive();
  });

  setUp(() async {
    await Hive.box<Map>('transactions').clear();
    await Hive.box<Map>('pocket_state').clear();
    await Hive.box<Map>('app_settings').clear();
    await Hive.box<Map>('pending_commit').clear();
  });

  test(
    'preview uses pocket snapshot and does not mutate stored counts',
    () async {
      await Hive.box<Map>('pocket_state').put('current', <String, dynamic>{
        'counts': <String, int>{
          '20000': 0,
          '10000': 0,
          '5000': 0,
          '2000': 0,
          '1000': 2,
          '500': 0,
          '100': 0,
          '50': 0,
        },
      });

      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);

      final result = container.read(collectResultProvider);

      expect(result, isNotNull);
      expect(result!.bestChangePlanItems[1000], 2);
      expect(container.read(pocketProvider).counts[1000], 2);
    },
  );

  test(
    'confirm with Pocket Mode on saves transaction and applies pocketAfter',
    () async {
      await Hive.box<Map>('pocket_state').put('current', <String, dynamic>{
        'counts': <String, int>{
          '20000': 0,
          '10000': 0,
          '5000': 0,
          '2000': 0,
          '1000': 2,
          '500': 0,
          '100': 0,
          '50': 0,
        },
      });

      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);

      final bool confirmed = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();

      expect(confirmed, isTrue);
      expect(Hive.box<Map>('transactions').isNotEmpty, isTrue);
      expect(Hive.box<Map>('pending_commit').isEmpty, isTrue);
      expect(container.read(pocketProvider).counts[5000], 1);
      expect(container.read(pocketProvider).counts[1000], 0);
    },
  );

  test('confirm with Pocket Mode off leaves pocket unchanged', () async {
    await Hive.box<Map>('pocket_state').put('current', <String, dynamic>{
      'counts': <String, int>{
        '20000': 0,
        '10000': 0,
        '5000': 0,
        '2000': 0,
        '1000': 2,
        '500': 0,
        '100': 0,
        '50': 0,
      },
    });

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.notifier).setPocketModeEnabled(false);

    container.read(collectProvider.notifier).startDraft();
    container.read(collectProvider.notifier).setDraftRidersCount(2);
    container.read(collectProvider.notifier).setDraftReceivedDenominationsMinor(
      <int>[2000, 1000],
    );

    final bool confirmed = await container
        .read(collectProvider.notifier)
        .confirmDraftTransaction();

    expect(confirmed, isTrue);
    expect(Hive.box<Map>('transactions').isNotEmpty, isTrue);
    expect(container.read(pocketProvider).counts[2000], 0);
    expect(container.read(pocketProvider).counts[1000], 2);
  });

  test(
    'saving an underpaid transaction creates an open collect settlement',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[2000]);

      final bool confirmed = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();

      expect(confirmed, isTrue);

      final TransactionRecord record = container
          .read(transactionsProvider)
          .single;
      expect(record.settlementDirection, SettlementDirection.collectMore);
      expect(record.settlementStatus, SettlementStatus.open);
      expect(record.remainingToCollectMinor, 1000);
      expect(record.remainingToReturnMinor, 0);

      final openSettlements = container.read(openSettlementsProvider);
      expect(openSettlements, hasLength(1));
      expect(
        openSettlements.single.resolutionState,
        SettlementResolutionState.waitingOnPassenger,
      );
      expect(openSettlements.single.currentSuggestedPlan[1000], 1);
    },
  );

  test(
    'saving an infeasible change transaction creates an open return settlement',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(collectProvider.notifier).setFareMinor(2000);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);

      final bool confirmed = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();

      expect(confirmed, isTrue);

      final TransactionRecord record = container
          .read(transactionsProvider)
          .single;
      expect(record.settlementDirection, SettlementDirection.returnChange);
      expect(record.settlementStatus, SettlementStatus.open);
      expect(record.remainingToReturnMinor, 1000);

      final openSettlements = container.read(openSettlementsProvider);
      expect(openSettlements, hasLength(1));
      expect(
        openSettlements.single.resolutionState,
        SettlementResolutionState.blocked,
      );
    },
  );

  test(
    'confirming partial collect settlement appends an event and keeps record open',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[2000]);
      final bool confirmed = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(confirmed, isTrue);

      final TransactionRecord openRecord = container
          .read(transactionsProvider)
          .single;
      final bool settledPartially = await container
          .read(collectProvider.notifier)
          .confirmSettlement(
            recordId: openRecord.id,
            receivedNowDenominationsMinor: const <int>[500],
          );

      expect(settledPartially, isTrue);

      final TransactionRecord updated = container
          .read(transactionsProvider)
          .single;
      expect(updated.settlementStatus, SettlementStatus.partiallySettled);
      expect(updated.remainingToCollectMinor, 500);
      expect(updated.remainingToReturnMinor, 0);
      expect(updated.settlementEvents, hasLength(1));
      expect(updated.settlementEvents.single.receivedDenominationsMinor, <int>[
        500,
      ]);
      expect(container.read(pocketProvider).counts[500], 1);
    },
  );

  test(
    'confirming a full return settlement closes the record and updates pocket',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(collectProvider.notifier).setFareMinor(2000);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);
      final bool created = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(created, isTrue);

      await container
          .read(pocketProvider.notifier)
          .replaceInventory(
            const PocketInventory(<int, int>{
              20000: 0,
              10000: 0,
              5000: 1,
              2000: 0,
              1000: 1,
              500: 0,
              100: 0,
              50: 0,
            }),
          );

      final TransactionRecord openRecord = container
          .read(transactionsProvider)
          .single;
      final bool settled = await container
          .read(collectProvider.notifier)
          .confirmSettlement(
            recordId: openRecord.id,
            returnedNowDenominationsMinor: const <int>[1000],
          );

      expect(settled, isTrue);

      final TransactionRecord updated = container
          .read(transactionsProvider)
          .single;
      expect(updated.settlementStatus, SettlementStatus.settled);
      expect(updated.remainingToCollectMinor, 0);
      expect(updated.remainingToReturnMinor, 0);
      expect(updated.settlementDirection, isNull);
      expect(updated.settlementEvents, hasLength(1));
      expect(container.read(openSettlementsProvider), isEmpty);
      expect(container.read(pocketProvider).counts[1000], 0);
    },
  );

  test('deleting a transaction restores the pocket counts correctly', () async {
    await Hive.box<Map>('pocket_state').put('current', <String, dynamic>{
      'counts': <String, int>{
        '20000': 0,
        '10000': 0,
        '5000': 0,
        '2000': 0,
        '1000': 2,
        '500': 0,
        '100': 0,
        '50': 0,
      },
    });

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(collectProvider.notifier).startDraft();
    container.read(collectProvider.notifier).setDraftRidersCount(2);
    container.read(collectProvider.notifier).setDraftReceivedDenominationsMinor(
      <int>[5000],
    );

    final bool confirmed = await container
        .read(collectProvider.notifier)
        .confirmDraftTransaction();
    expect(confirmed, isTrue);

    final TransactionRecord record = container
        .read(transactionsProvider)
        .single;
    await container.read(collectProvider.notifier).deleteTransaction(record);

    expect(Hive.box<Map>('transactions').isEmpty, isTrue);
    expect(container.read(pocketProvider).counts[5000], 0);
    expect(container.read(pocketProvider).counts[1000], 2);
  });

  test(
    'open return settlements re-evaluate after new pocket-affecting transactions',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(collectProvider.notifier).setFareMinor(2000);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);
      final bool created = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(created, isTrue);

      expect(
        container.read(openSettlementsProvider).single.resolutionState,
        SettlementResolutionState.blocked,
      );

      container.read(collectProvider.notifier).setFareMinor(1500);
      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(1);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[1000, 500]);
      final bool addedCash = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(addedCash, isTrue);

      final openSettlements = container.read(openSettlementsProvider);
      expect(openSettlements, hasLength(1));
      expect(
        openSettlements.single.resolutionState,
        SettlementResolutionState.resolvableNow,
      );
      expect(openSettlements.single.currentSuggestedPlan[1000], 1);
      expect(
        container.read(collectProvider).newlyResolvableSettlements,
        hasLength(1),
      );
      expect(
        container
            .read(collectProvider)
            .newlyResolvableSettlements
            .single
            .record
            .remainingToReturnMinor,
        1000,
      );
    },
  );

  test(
    'open return settlements use grouped pocket allocation across all pending returns',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).setFareMinor(2000);
      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);
      final bool firstCreated = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(firstCreated, isTrue);

      container.read(collectProvider.notifier).setFareMinor(1750);
      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);
      final bool secondCreated = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(secondCreated, isTrue);

      await container
          .read(pocketProvider.notifier)
          .replaceInventory(
            const PocketInventory(<int, int>{
              20000: 0,
              10000: 0,
              5000: 0,
              2000: 0,
              1000: 1,
              500: 0,
              100: 0,
              50: 0,
            }),
          );

      final openSettlements = container.read(openSettlementsProvider);
      expect(openSettlements, hasLength(2));

      final OpenSettlementView resolvable = openSettlements.firstWhere(
        (OpenSettlementView item) => item.record.remainingToReturnMinor == 1000,
      );
      final OpenSettlementView blocked = openSettlements.firstWhere(
        (OpenSettlementView item) => item.record.remainingToReturnMinor == 1500,
      );

      expect(
        resolvable.resolutionState,
        SettlementResolutionState.resolvableNow,
      );
      expect(resolvable.currentSuggestedPlan[1000], 1);
      expect(blocked.resolutionState, SettlementResolutionState.blocked);
      expect(blocked.currentSuggestedPlan, isEmpty);
    },
  );

  test(
    'multiple blocked return settlements become newly resolvable together after cash is added',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).setFareMinor(1500);

      for (int index = 0; index < 2; index++) {
        container.read(collectProvider.notifier).startDraft();
        container.read(collectProvider.notifier).setDraftRidersCount(1);
        container
            .read(collectProvider.notifier)
            .setDraftReceivedDenominationsMinor(<int>[2000]);
        final bool created = await container
            .read(collectProvider.notifier)
            .confirmDraftTransaction();
        expect(created, isTrue);
      }

      final List<OpenSettlementView> before = container.read(
        openSettlementsProvider,
      );
      expect(before, hasLength(2));
      expect(
        before.every(
          (OpenSettlementView item) =>
              item.resolutionState == SettlementResolutionState.blocked,
        ),
        isTrue,
      );

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(1);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[500, 500, 500]);
      final bool addedCash = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();

      expect(addedCash, isTrue);

      final List<OpenSettlementView> after = container.read(
        openSettlementsProvider,
      );
      expect(after, hasLength(2));
      expect(
        after.every(
          (OpenSettlementView item) =>
              item.resolutionState == SettlementResolutionState.resolvableNow,
        ),
        isTrue,
      );
      expect(
        container.read(collectProvider).newlyResolvableSettlements,
        hasLength(2),
      );
      expect(
        container
            .read(collectProvider)
            .newlyResolvableSettlements
            .every(
              (OpenSettlementView item) => item.currentSuggestedPlan[500] == 1,
            ),
        isTrue,
      );

      container
          .read(collectProvider.notifier)
          .clearNewlyResolvableSettlements();
      expect(
        container.read(collectProvider).newlyResolvableSettlements,
        isEmpty,
      );
    },
  );

  test(
    'overpaying an open collect settlement converts it into an open return settlement when change is unavailable',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[2000]);
      final bool created = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(created, isTrue);

      final TransactionRecord openRecord = container
          .read(transactionsProvider)
          .single;
      expect(openRecord.settlementDirection, SettlementDirection.collectMore);
      expect(openRecord.remainingToCollectMinor, 1000);

      final bool settled = await container
          .read(collectProvider.notifier)
          .confirmSettlement(
            recordId: openRecord.id,
            receivedNowDenominationsMinor: const <int>[2000],
          );

      expect(settled, isTrue);

      final TransactionRecord updated = container
          .read(transactionsProvider)
          .single;
      expect(updated.settlementStatus, SettlementStatus.partiallySettled);
      expect(updated.settlementDirection, SettlementDirection.returnChange);
      expect(updated.remainingToCollectMinor, 0);
      expect(updated.remainingToReturnMinor, 1000);
      expect(updated.settlementEvents, hasLength(1));
      expect(updated.settlementEvents.single.receivedDenominationsMinor, <int>[
        2000,
      ]);

      final OpenSettlementView settlementView = container
          .read(openSettlementsProvider)
          .single;
      expect(settlementView.resolutionState, SettlementResolutionState.blocked);
    },
  );

  test(
    'adding a transaction that does not unlock old settlements leaves newly resolvable list empty',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(collectProvider.notifier).setFareMinor(1500);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(1);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[2000]);
      final bool firstCreated = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();
      expect(firstCreated, isTrue);

      expect(
        container.read(openSettlementsProvider).single.resolutionState,
        SettlementResolutionState.blocked,
      );
      container
          .read(collectProvider.notifier)
          .clearNewlyResolvableSettlements();

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(1);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[5000]);
      final bool secondCreated = await container
          .read(collectProvider.notifier)
          .confirmDraftTransaction();

      expect(secondCreated, isTrue);
      expect(
        container.read(collectProvider).newlyResolvableSettlements,
        isEmpty,
      );
    },
  );

  test('recovery finishes a pending commit and clears it', () async {
    final TransactionRecord record = TransactionRecord(
      id: 'commit-1',
      createdAt: DateTime(2026, 3, 18),
      fareMinor: 1500,
      ridersCount: 2,
      receivedDenominationsMinor: const <int>[5000],
      amountPaidMinor: 5000,
      totalDueMinor: 3000,
      changeDueMinor: 2000,
      changePlanItems: const <int, int>{1000: 2},
      alternativePlanItems: const <Map<int, int>>[
        <int, int>{500: 4},
      ],
      completionPlanItems: const <int, int>{},
      feasible: true,
      manualOverride: false,
      engineModeUsed: 'smartDp',
      changeStatus: 'exact',
      engineWarnings: const <String>[],
      settlementStatus: SettlementStatus.settled,
      settlementDirection: null,
      remainingToCollectMinor: 0,
      remainingToReturnMinor: 0,
      settlementEvents: const <SettlementEvent>[],
      engineNote: null,
    );
    final PendingCommit commit = PendingCommit(
      id: 'commit-1',
      records: <TransactionRecord>[record],
      pocketModeEnabled: true,
      pocketAfter: PocketInventory(<int, int>{
        20000: 0,
        10000: 0,
        5000: 1,
        2000: 0,
        1000: 0,
        500: 0,
        100: 0,
        50: 0,
      }),
    );
    await Hive.box<Map>('pending_commit').put('current', commit.toJson());

    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(collectProvider);
    await _flushAsyncWork();

    expect(Hive.box<Map>('pending_commit').isEmpty, isTrue);
    expect(Hive.box<Map>('transactions').containsKey('commit-1'), isTrue);
    expect(container.read(pocketProvider).counts[5000], 1);
  });

  test(
    'batch preview uses incoming payments and does not mutate persisted pocket',
    () async {
      await Hive.box<Map>('pocket_state').put('current', <String, dynamic>{
        'counts': <String, int>{
          '20000': 0,
          '10000': 0,
          '5000': 0,
          '2000': 0,
          '1000': 0,
          '500': 0,
          '100': 0,
          '50': 0,
        },
      });

      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(collectProvider.notifier).setFareMinor(500);

      final BatchAllocationResult preview = await container
          .read(collectProvider.notifier)
          .previewBatchAllocation(
            payments: <PassengerPayment>[
              PassengerPayment.fromDenominations(
                id: 'a',
                riders: 1,
                receivedDenominationsMinor: const <int>[1000],
              ),
              PassengerPayment.fromDenominations(
                id: 'b',
                riders: 1,
                receivedDenominationsMinor: const <int>[500],
              ),
            ],
          );

      final ChangePlan planA = preview.plans.firstWhere(
        (ChangePlan plan) => plan.passengerId == 'a',
      );

      expect(planA.items.single.denomMinor, 500);
      expect(container.read(pocketProvider).counts[500], 0);
      expect(preview.pocketAfter.countOf(500), 0);
    },
  );

  test(
    'start new trip clears both open settlements and closed transactions',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(2);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[2000]);
      await container.read(collectProvider.notifier).confirmDraftTransaction();

      container.read(collectProvider.notifier).startDraft();
      container.read(collectProvider.notifier).setDraftRidersCount(1);
      container
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(<int>[1500]);
      await container.read(collectProvider.notifier).confirmDraftTransaction();

      expect(container.read(transactionsProvider), hasLength(2));
      expect(container.read(openSettlementsProvider), hasLength(1));

      await container.read(collectProvider.notifier).startNewTrip();

      expect(container.read(transactionsProvider), isEmpty);
      expect(container.read(openSettlementsProvider), isEmpty);
    },
  );
}
