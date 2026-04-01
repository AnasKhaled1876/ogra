import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/analytics/analytics_provider.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../engine/engine_facade.dart';
import '../../../engine/models.dart' as engine;
import '../../../engine/riverpod_providers.dart';
import '../../pocket/application/pocket_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../data/local_transaction_repo.dart';
import '../data/pending_commit_repo.dart';
import '../domain/pending_commit.dart';
import '../domain/settlement_models.dart';
import '../domain/settlement_preview.dart';
import '../domain/transaction_draft.dart';
import '../domain/transaction_record.dart';
import '../domain/transaction_result.dart';
import 'collect_state.dart';
import 'open_settlement_view.dart';

final transactionRepoProvider = Provider<LocalTransactionRepo>((Ref ref) {
  return LocalTransactionRepo(Hive.box<Map>('transactions'));
});

final pendingCommitRepoProvider = Provider<PendingCommitRepo>((Ref ref) {
  return PendingCommitRepo(Hive.box<Map>('pending_commit'));
});

final transactionsRefreshProvider = StateProvider<int>((Ref ref) => 0);

final transactionsProvider = Provider<List<TransactionRecord>>((Ref ref) {
  ref.watch(transactionsRefreshProvider);
  return ref.watch(transactionRepoProvider).load();
});

final settledTransactionsProvider = Provider<List<TransactionRecord>>((
  Ref ref,
) {
  return ref
      .watch(transactionsProvider)
      .where((TransactionRecord record) => record.isSettled)
      .toList(growable: false);
});

final openSettlementsProvider = Provider<List<OpenSettlementView>>((Ref ref) {
  final List<TransactionRecord> openRecords = ref
      .watch(transactionsProvider)
      .where((TransactionRecord record) => record.isOpen)
      .toList(growable: false);
  final bool pocketModeEnabled = ref.watch(
    settingsProvider.select((settings) => settings.pocketModeEnabled),
  );
  final engine.PocketInventory pocketBefore = pocketModeEnabled
      ? ref.watch(pocketProvider)
      : engine.PocketInventory.initial();
  final ChangeDistributionEngine engineFacade = ref.watch(engineProvider);
  final engine.EngineConfig config = ref.watch(engineConfigProvider);
  final Map<String, OpenSettlementView> viewsByRecordId =
      <String, OpenSettlementView>{};

  for (final TransactionRecord record in openRecords) {
    if (record.settlementDirection == SettlementDirection.collectMore) {
      viewsByRecordId[record.id] = OpenSettlementView(
        record: record,
        resolutionState: SettlementResolutionState.waitingOnPassenger,
        currentSuggestedPlan: record.completionPlanItems,
        currentAlternativePlans: const <Map<int, int>>[],
        currentWarnings: const <String>[],
      );
    }
  }

  final List<TransactionRecord> returnRecords = openRecords
      .where(
        (TransactionRecord record) =>
            record.settlementDirection == SettlementDirection.returnChange,
      )
      .toList(growable: false);

  if (returnRecords.isNotEmpty) {
    if (!pocketModeEnabled) {
      for (final TransactionRecord record in returnRecords) {
        viewsByRecordId[record.id] = OpenSettlementView(
          record: record,
          resolutionState: SettlementResolutionState.blocked,
          currentSuggestedPlan: const <int, int>{},
          currentAlternativePlans: const <Map<int, int>>[],
          currentWarnings: const <String>[
            'فعّل الفكة علشان التوصيات تستخدم كل الفلوس المتاحة في الرحلة.',
          ],
        );
      }
    } else {
      final engine.BatchAllocationResult groupedPreview = engineFacade
          .previewGroupedReturns(
            returnDues: returnRecords
                .map(
                  (TransactionRecord record) => engine.PassengerDue(
                    id: record.id,
                    riders: record.ridersCount,
                    dueMinor: 0,
                    paidMinor: record.remainingToReturnMinor,
                    changeDueMinor: record.remainingToReturnMinor,
                  ),
                )
                .toList(growable: false),
            pocketBefore: pocketBefore,
            config: config,
            startedAt: DateTime.now(),
          );
      final Map<String, engine.ChangePlan> planByRecordId =
          <String, engine.ChangePlan>{
            for (final engine.ChangePlan plan in groupedPreview.plans)
              plan.passengerId: plan,
          };

      for (final TransactionRecord record in returnRecords) {
        final engine.ChangePlan primaryPlan =
            planByRecordId[record.id] ?? engine.ChangePlan.empty;
        final Map<int, int> suggestedPlan = _mapPlanItems(primaryPlan.items);
        viewsByRecordId[record.id] = OpenSettlementView(
          record: record,
          resolutionState:
              primaryPlan.status == engine.ChangeStatus.infeasible ||
                  suggestedPlan.isEmpty
              ? SettlementResolutionState.blocked
              : SettlementResolutionState.resolvableNow,
          currentSuggestedPlan: suggestedPlan,
          currentAlternativePlans: const <Map<int, int>>[],
          currentWarnings: <String>[
            ...groupedPreview.warnings,
            if (primaryPlan.note != null && primaryPlan.note!.isNotEmpty)
              primaryPlan.note!,
            'الخطة دي محسوبة مع باقي التسويات المفتوحة الحالية.',
          ],
        );
      }
    }
  }

  return openRecords
      .map((TransactionRecord record) => viewsByRecordId[record.id]!)
      .toList(growable: false);
});

final collectProvider = NotifierProvider<CollectController, CollectState>(
  CollectController.new,
);

final collectResultProvider = Provider<TransactionResult?>((Ref ref) {
  final CollectState state = ref.watch(collectProvider);
  final TransactionDraft? draft = state.draft;
  if (draft == null || draft.receivedDenominationsMinor.isEmpty) {
    return null;
  }

  final bool pocketMode = ref.watch(
    settingsProvider.select((appSettings) => appSettings.pocketModeEnabled),
  );
  final engine.PocketInventory pocketBefore = pocketMode
      ? ref.watch(pocketProvider)
      : engine.PocketInventory.initial();
  final ChangeDistributionEngine engineFacade = ref.watch(engineProvider);
  final engine.EngineConfig config = ref.watch(engineConfigProvider);
  final engine.PassengerPayment payment =
      engine.PassengerPayment.fromDenominations(
        id: 'draft',
        riders: draft.ridersCount,
        receivedDenominationsMinor: draft.receivedDenominationsMinor,
      );

  final engine.BatchAllocationResult preview = engineFacade.previewSingle(
    farePerRiderMinor: state.fareMinor,
    payment: payment,
    pocketBefore: pocketBefore,
    config: config,
    startedAt: DateTime.now(),
  );

  return _mapEnginePreviewToTransactionResult(preview);
});

class CollectController extends Notifier<CollectState> {
  late final LocalTransactionRepo _repo;
  late final PendingCommitRepo _pendingCommitRepo;
  bool _recoveryScheduled = false;

  AnalyticsService get _analytics => ref.read(analyticsProvider);

  @override
  CollectState build() {
    _repo = ref.read(transactionRepoProvider);
    _pendingCommitRepo = ref.read(pendingCommitRepoProvider);
    final int defaultFareMinor = ref.read(settingsProvider).defaultFareMinor;
    if (!_recoveryScheduled && _pendingCommitRepo.load() != null) {
      _recoveryScheduled = true;
      Future<void>.microtask(recoverPendingCommit);
    }

    return CollectState(fareMinor: defaultFareMinor);
  }

  void setFareMinor(int fareMinor) {
    final int oldFare = state.fareMinor;
    final int newFare = max(100, fareMinor);
    state = state.copyWith(fareMinor: newFare);
    if (oldFare != newFare) {
      _analytics.logFareAdjusted(oldFareMinor: oldFare, newFareMinor: newFare);
    }
  }

  void adjustFareMinor(int deltaMinor) {
    setFareMinor(state.fareMinor + deltaMinor);
  }

  void applyPreset({
    required int fareMinor,
    required int ridersCount,
    required int amountPaidMinor,
  }) {
    state = state.copyWith(fareMinor: fareMinor);
  }

  void startDraft() {
    state = state.copyWith(draft: TransactionDraft.initial());
    _analytics.logSheetOpened();
  }

  void setDraftRidersCount(int count) {
    final TransactionDraft? draft = state.draft;
    if (draft == null) {
      return;
    }

    state = state.copyWith(
      draft: draft.copyWith(ridersCount: count.clamp(1, 14)),
    );
  }

  void setDraftReceivedDenominationsMinor(List<int> values) {
    final TransactionDraft? draft = state.draft;
    if (draft == null) {
      return;
    }

    state = state.copyWith(
      draft: draft.copyWith(
        receivedDenominationsMinor: List<int>.unmodifiable(values),
      ),
    );
  }

  void resetDraft() {
    state = state.copyWith(clearDraft: true);
  }

  List<TransactionRecord> loadOpenSettlements() {
    return _repo
        .load()
        .where((TransactionRecord record) => record.isOpen)
        .toList(growable: false);
  }

  Future<bool> confirmDraftTransaction() async {
    final TransactionDraft? draft = state.draft;
    if (draft == null || draft.receivedDenominationsMinor.isEmpty) {
      state = state.copyWith(snackMessage: 'اكتب الفلوس اللي استلمتها الأول.');
      return false;
    }
    final Set<String> resolvableBefore = ref
        .read(openSettlementsProvider)
        .where(
          (OpenSettlementView item) =>
              item.resolutionState == SettlementResolutionState.resolvableNow,
        )
        .map((OpenSettlementView item) => item.record.id)
        .toSet();

    final _DraftEvaluation? evaluation = _previewDraft(draft);
    final TransactionResult? result = evaluation?.result;
    if (result == null) {
      state = state.copyWith(snackMessage: 'ابدأ عملية جديدة الأول.');
      return false;
    }

    final DateTime now = DateTime.now();
    final _InitialSettlementState settlementState = _initialSettlementState(
      result: result,
    );
    final TransactionRecord record = TransactionRecord(
      id: now.microsecondsSinceEpoch.toString(),
      createdAt: now,
      fareMinor: state.fareMinor,
      ridersCount: draft.ridersCount,
      receivedDenominationsMinor: draft.receivedDenominationsMinor,
      amountPaidMinor: draft.amountPaidMinor,
      totalDueMinor: result.totalDueMinor,
      changeDueMinor: result.changeDueMinor,
      changePlanItems: result.bestChangePlanItems,
      alternativePlanItems: result.alternativePlanItems,
      completionPlanItems: result.completionPlanItems,
      feasible: result.feasible,
      manualOverride: false,
      engineModeUsed: result.modeUsed,
      changeStatus: result.engineStatus,
      engineWarnings: result.warnings,
      settlementStatus: settlementState.status,
      settlementDirection: settlementState.direction,
      remainingToCollectMinor: settlementState.remainingToCollectMinor,
      remainingToReturnMinor: settlementState.remainingToReturnMinor,
      settlementEvents: const <SettlementEvent>[],
      engineNote: result.note,
    );

    final bool pocketModeEnabled = ref.read(settingsProvider).pocketModeEnabled;
    final PendingCommit commit = PendingCommit(
      id: record.id,
      records: <TransactionRecord>[record],
      pocketModeEnabled: pocketModeEnabled,
      pocketAfter: pocketModeEnabled ? evaluation!.preview.pocketAfter : null,
    );

    final bool saved = await _persistCommit(
      commit: commit,
      failureMessage:
          'حصلت مشكلة أثناء الحفظ. هنكملها تلقائيًا أول ما التطبيق يفتح.',
    );
    if (!saved) {
      return false;
    }

    _analytics.logTransactionCompleted(
      ridersCount: draft.ridersCount,
      fareMinor: state.fareMinor,
      amountPaidMinor: draft.amountPaidMinor,
      changeDueMinor: result.changeDueMinor,
      isFeasible: result.feasible,
      pocketModeEnabled: pocketModeEnabled,
      denominationsMinor: draft.receivedDenominationsMinor,
      changePlanItems: result.bestChangePlanItems,
      engineMode: result.modeUsed,
    );
    if (!result.feasible) {
      _analytics.logChangeInfeasible(
        changeDueMinor: result.changeDueMinor.abs(),
        ridersCount: draft.ridersCount,
        fareMinor: state.fareMinor,
      );
    }

    _refreshTransactions();
    final List<OpenSettlementView> newlyResolvableSettlements = ref
        .read(openSettlementsProvider)
        .where(
          (OpenSettlementView item) =>
              item.resolutionState == SettlementResolutionState.resolvableNow &&
              !resolvableBefore.contains(item.record.id),
        )
        .toList(growable: false);
    state = CollectState(
      fareMinor: ref.read(settingsProvider).defaultFareMinor,
      snackMessage: settlementState.status == SettlementStatus.settled
          ? 'تم تسجيل العملية.'
          : 'تم تسجيل العملية كتسوية مفتوحة.',
      newlyResolvableSettlements: newlyResolvableSettlements,
    );
    return true;
  }

  SettlementPreview? previewSettlement({
    required String recordId,
    List<int> receivedNowDenominationsMinor = const <int>[],
    List<int> returnedNowDenominationsMinor = const <int>[],
  }) {
    final TransactionRecord? record = _findRecord(recordId);
    if (record == null ||
        record.isSettled ||
        record.settlementDirection == null) {
      return null;
    }

    return _evaluateSettlement(
      record: record,
      receivedNowDenominationsMinor: receivedNowDenominationsMinor,
      returnedNowDenominationsMinor: returnedNowDenominationsMinor,
    )?.preview;
  }

  Future<bool> confirmSettlement({
    required String recordId,
    List<int> receivedNowDenominationsMinor = const <int>[],
    List<int> returnedNowDenominationsMinor = const <int>[],
  }) async {
    final TransactionRecord? record = _findRecord(recordId);
    if (record == null ||
        record.isSettled ||
        record.settlementDirection == null) {
      state = state.copyWith(snackMessage: 'التسوية دي مش متاحة دلوقتي.');
      return false;
    }

    if (record.settlementDirection == SettlementDirection.collectMore &&
        receivedNowDenominationsMinor.isEmpty) {
      state = state.copyWith(snackMessage: 'اكتب الفلوس اللي استلمتها دلوقتي.');
      return false;
    }

    if (record.settlementDirection == SettlementDirection.returnChange &&
        returnedNowDenominationsMinor.isEmpty) {
      state = state.copyWith(
        snackMessage: 'اكتب أو اختار الفئات اللي هترجعها.',
      );
      return false;
    }

    final _SettlementEvaluation? evaluation = _evaluateSettlement(
      record: record,
      receivedNowDenominationsMinor: receivedNowDenominationsMinor,
      returnedNowDenominationsMinor: returnedNowDenominationsMinor,
    );
    final SettlementPreview? preview = evaluation?.preview;
    if (preview == null) {
      state = state.copyWith(snackMessage: 'تعذر تجهيز التسوية.');
      return false;
    }

    if (!preview.feasible) {
      state = state.copyWith(
        snackMessage: preview.invalidReason ?? 'التسوية دي مش ممكنة بالشكل ده.',
      );
      return false;
    }

    final List<int> actualReturnedDenominationsMinor =
        returnedNowDenominationsMinor.isNotEmpty
        ? returnedNowDenominationsMinor
        : _expandDenominationCounts(preview.currentSuggestedPlan);
    final DateTime now = DateTime.now();
    final SettlementEvent event = SettlementEvent(
      id: '${record.id}_${now.microsecondsSinceEpoch}',
      createdAt: now,
      receivedDenominationsMinor: receivedNowDenominationsMinor,
      returnedDenominationsMinor: actualReturnedDenominationsMinor,
      remainingToCollectMinorAfter: preview.remainingToCollectMinorAfter,
      remainingToReturnMinorAfter: preview.remainingToReturnMinorAfter,
      note: preview.note,
    );
    final SettlementDirection? nextDirection =
        preview.remainingToCollectMinorAfter > 0
        ? SettlementDirection.collectMore
        : preview.remainingToReturnMinorAfter > 0
        ? SettlementDirection.returnChange
        : null;
    final TransactionRecord updatedRecord = record.copyWith(
      completionPlanItems: nextDirection == SettlementDirection.collectMore
          ? preview.currentCompletionPlan
          : const <int, int>{},
      feasible: _nextFeasible(
        remainingToCollectMinor: preview.remainingToCollectMinorAfter,
        remainingToReturnMinor: preview.remainingToReturnMinorAfter,
        hasSuggestedPlan: preview.currentSuggestedPlan.isNotEmpty,
      ),
      changeStatus: _nextChangeStatus(
        remainingToCollectMinor: preview.remainingToCollectMinorAfter,
        remainingToReturnMinor: preview.remainingToReturnMinorAfter,
        hasSuggestedPlan: preview.currentSuggestedPlan.isNotEmpty,
      ),
      engineWarnings: preview.warnings,
      settlementStatus: preview.statusAfter,
      settlementDirection: nextDirection,
      clearSettlementDirection: nextDirection == null,
      remainingToCollectMinor: preview.remainingToCollectMinorAfter,
      remainingToReturnMinor: preview.remainingToReturnMinorAfter,
      settlementEvents: <SettlementEvent>[...record.settlementEvents, event],
      engineNote: preview.note,
      clearEngineNote: preview.note == null,
    );

    final bool pocketModeEnabled = ref.read(settingsProvider).pocketModeEnabled;
    final PendingCommit commit = PendingCommit(
      id: updatedRecord.id,
      records: <TransactionRecord>[updatedRecord],
      pocketModeEnabled: pocketModeEnabled,
      pocketAfter: pocketModeEnabled ? evaluation!.pocketAfter : null,
    );

    final bool saved = await _persistCommit(
      commit: commit,
      failureMessage:
          'حصلت مشكلة أثناء حفظ التسوية. هنكملها تلقائيًا أول ما التطبيق يفتح.',
    );
    if (!saved) {
      return false;
    }

    _analytics.logSettlementResolved(
      amountMinor: record.remainingToReturnMinor + record.remainingToCollectMinor,
    );

    _refreshTransactions();
    state = state.copyWith(
      snackMessage: preview.isClosed
          ? 'تمت التسوية بالكامل.'
          : 'تم تحديث التسوية ولسه فيها باقي مفتوح.',
    );
    return true;
  }

  void clearSnackMessage() {
    state = state.copyWith(clearSnackMessage: true);
  }

  void clearNewlyResolvableSettlements() {
    state = state.copyWith(clearNewlyResolvableSettlements: true);
  }

  Future<void> deleteTransaction(TransactionRecord record) async {
    await _repo.delete(record.id);

    if (ref.read(settingsProvider).pocketModeEnabled) {
      await ref
          .read(pocketProvider.notifier)
          .revertTransaction(
            receivedDenominationsMinor: record.allReceivedDenominationsMinor,
            changeToRestore: record.allReturnedDenominationCounts,
          );
    }

    _refreshTransactions();
    state = state.copyWith(snackMessage: 'تم حذف العملية.');
  }

  Future<void> startNewTrip() async {
    await _repo.clear();
    _refreshTransactions();
    state = state.copyWith(
      snackMessage: 'تم بدء رحلة جديدة ومسح العمليات السابقة.',
    );
  }

  Future<engine.BatchAllocationResult> previewBatchAllocation({
    required List<engine.PassengerPayment> payments,
  }) {
    final ChangeDistributionEngine engineFacade = ref.read(engineProvider);
    final engine.EngineConfig config = ref.read(engineConfigProvider);
    final bool pocketMode = ref.read(settingsProvider).pocketModeEnabled;
    final engine.PocketInventory pocketBefore = pocketMode
        ? ref.read(pocketProvider)
        : engine.PocketInventory.initial();

    return engineFacade.allocateBatch(
      farePerRiderMinor: state.fareMinor,
      payments: payments,
      pocketBefore: pocketBefore,
      config: config,
      startedAt: DateTime.now(),
    );
  }

  Future<void> recoverPendingCommit() async {
    final PendingCommit? pendingCommit = _pendingCommitRepo.load();
    if (pendingCommit == null) {
      return;
    }

    await _repo.saveAll(pendingCommit.records);
    if (pendingCommit.pocketModeEnabled && pendingCommit.pocketAfter != null) {
      await ref
          .read(pocketProvider.notifier)
          .replaceInventory(pendingCommit.pocketAfter!);
    }
    await _pendingCommitRepo.clear();
    _refreshTransactions();
  }

  _DraftEvaluation? _previewDraft(TransactionDraft draft) {
    if (draft.receivedDenominationsMinor.isEmpty) {
      return null;
    }

    final bool pocketMode = ref.read(settingsProvider).pocketModeEnabled;
    final engine.PocketInventory pocketBefore = pocketMode
        ? ref.read(pocketProvider)
        : engine.PocketInventory.initial();
    final ChangeDistributionEngine engineFacade = ref.read(engineProvider);
    final engine.EngineConfig config = ref.read(engineConfigProvider);
    final engine.PassengerPayment payment =
        engine.PassengerPayment.fromDenominations(
          id: 'draft',
          riders: draft.ridersCount,
          receivedDenominationsMinor: draft.receivedDenominationsMinor,
        );

    final engine.BatchAllocationResult preview = engineFacade.previewSingle(
      farePerRiderMinor: state.fareMinor,
      payment: payment,
      pocketBefore: pocketBefore,
      config: config,
      startedAt: DateTime.now(),
    );

    return _DraftEvaluation(
      preview: preview,
      result: _mapEnginePreviewToTransactionResult(preview),
    );
  }

  _SettlementEvaluation? _evaluateSettlement({
    required TransactionRecord record,
    List<int> receivedNowDenominationsMinor = const <int>[],
    List<int> returnedNowDenominationsMinor = const <int>[],
  }) {
    final SettlementDirection? direction = record.settlementDirection;
    if (direction == null) {
      return null;
    }

    final bool pocketModeEnabled = ref.read(settingsProvider).pocketModeEnabled;
    final engine.PocketInventory pocketBefore = pocketModeEnabled
        ? ref.read(pocketProvider)
        : engine.PocketInventory.initial();
    final ChangeDistributionEngine engineFacade = ref.read(engineProvider);
    final engine.EngineConfig config = ref.read(engineConfigProvider);

    if (direction == SettlementDirection.collectMore) {
      if (receivedNowDenominationsMinor.isEmpty) {
        return _SettlementEvaluation(
          preview: SettlementPreview(
            recordId: record.id,
            direction: SettlementDirection.collectMore,
            receivedNowDenominationsMinor: const <int>[],
            returnedNowDenominationsMinor: const <int>[],
            appliedReceivedMinor: 0,
            appliedReturnedMinor: 0,
            remainingToCollectMinorAfter: record.remainingToCollectMinor,
            remainingToReturnMinorAfter: 0,
            statusAfter: _statusForRemaining(
              record: record,
              appliedNow: false,
              remainingToCollectMinor: record.remainingToCollectMinor,
              remainingToReturnMinor: 0,
            ),
            feasible: true,
            currentCompletionPlan: record.completionPlanItems,
            note: 'لسه منتظر باقي المبلغ.',
          ),
          pocketAfter: pocketBefore,
        );
      }

      final int appliedReceivedMinor = _sumDenominations(
        receivedNowDenominationsMinor,
      );
      final engine.BatchAllocationResult settlementPreview = engineFacade
          .previewDirectSettlement(
            dueMinor: record.remainingToCollectMinor,
            receivedDenominationsMinor: receivedNowDenominationsMinor,
            pocketBefore: pocketBefore,
            config: config,
            startedAt: DateTime.now(),
          );
      final engine.ChangePlan primaryPlan = settlementPreview.plans.first;
      final Map<int, int> suggestedPlan = _mapPlanItems(primaryPlan.items);

      if (primaryPlan.status == engine.ChangeStatus.underpaid) {
        return _SettlementEvaluation(
          preview: SettlementPreview(
            recordId: record.id,
            direction: SettlementDirection.collectMore,
            receivedNowDenominationsMinor: receivedNowDenominationsMinor,
            returnedNowDenominationsMinor: const <int>[],
            appliedReceivedMinor: appliedReceivedMinor,
            appliedReturnedMinor: 0,
            remainingToCollectMinorAfter: primaryPlan.changeDueMinor.abs(),
            remainingToReturnMinorAfter: 0,
            statusAfter: _statusForRemaining(
              record: record,
              appliedNow: true,
              remainingToCollectMinor: primaryPlan.changeDueMinor.abs(),
              remainingToReturnMinor: 0,
            ),
            feasible: true,
            currentCompletionPlan: suggestedPlan,
            warnings: settlementPreview.warnings,
            note: primaryPlan.note,
          ),
          pocketAfter: settlementPreview.pocketAfter,
        );
      }

      if (primaryPlan.status == engine.ChangeStatus.infeasible) {
        return _SettlementEvaluation(
          preview: SettlementPreview(
            recordId: record.id,
            direction: SettlementDirection.returnChange,
            receivedNowDenominationsMinor: receivedNowDenominationsMinor,
            returnedNowDenominationsMinor: const <int>[],
            appliedReceivedMinor: appliedReceivedMinor,
            appliedReturnedMinor: 0,
            remainingToCollectMinorAfter: 0,
            remainingToReturnMinorAfter: primaryPlan.changeDueMinor,
            statusAfter: _statusForRemaining(
              record: record,
              appliedNow: true,
              remainingToCollectMinor: 0,
              remainingToReturnMinor: primaryPlan.changeDueMinor,
            ),
            feasible: true,
            warnings: settlementPreview.warnings,
            note:
                'تم التحصيل ولسه باقي للراكب ${formatMoneyMinor(primaryPlan.changeDueMinor)}.',
          ),
          pocketAfter: settlementPreview.pocketAfter,
        );
      }

      return _SettlementEvaluation(
        preview: SettlementPreview(
          recordId: record.id,
          direction: SettlementDirection.collectMore,
          receivedNowDenominationsMinor: receivedNowDenominationsMinor,
          returnedNowDenominationsMinor: _expandDenominationCounts(
            suggestedPlan,
          ),
          appliedReceivedMinor: appliedReceivedMinor,
          appliedReturnedMinor: max(primaryPlan.changeDueMinor, 0),
          remainingToCollectMinorAfter: 0,
          remainingToReturnMinorAfter: 0,
          statusAfter: SettlementStatus.settled,
          feasible: true,
          currentSuggestedPlan: suggestedPlan,
          currentAlternativePlans: settlementPreview.plans
              .skip(1)
              .map((engine.ChangePlan plan) => _mapPlanItems(plan.items))
              .where((Map<int, int> plan) => plan.isNotEmpty)
              .toList(growable: false),
          warnings: settlementPreview.warnings,
          note: primaryPlan.changeDueMinor > 0
              ? 'تم التحصيل والرجوع بالباقي.'
              : 'تم التحصيل بالكامل.',
        ),
        pocketAfter: settlementPreview.pocketAfter,
      );
    }

    if (returnedNowDenominationsMinor.isEmpty) {
      if (!pocketModeEnabled) {
        return _SettlementEvaluation(
          preview: SettlementPreview(
            recordId: record.id,
            direction: SettlementDirection.returnChange,
            receivedNowDenominationsMinor: const <int>[],
            returnedNowDenominationsMinor: const <int>[],
            appliedReceivedMinor: 0,
            appliedReturnedMinor: 0,
            remainingToCollectMinorAfter: 0,
            remainingToReturnMinorAfter: record.remainingToReturnMinor,
            statusAfter: _statusForRemaining(
              record: record,
              appliedNow: false,
              remainingToCollectMinor: 0,
              remainingToReturnMinor: record.remainingToReturnMinor,
            ),
            feasible: true,
            warnings: const <String>[
              'فعّل الفكة علشان تعرف إذا كانت التسوية ممكنة دلوقتي.',
            ],
          ),
          pocketAfter: pocketBefore,
        );
      }

      final List<TransactionRecord> openReturnRecords = _repo
          .load()
          .where(
            (TransactionRecord item) =>
                item.isOpen &&
                item.settlementDirection == SettlementDirection.returnChange,
          )
          .toList(growable: false);
      final engine.BatchAllocationResult returnPreview = engineFacade
          .previewGroupedReturns(
            returnDues: openReturnRecords
                .map(
                  (TransactionRecord item) => engine.PassengerDue(
                    id: item.id,
                    riders: item.ridersCount,
                    dueMinor: 0,
                    paidMinor: item.remainingToReturnMinor,
                    changeDueMinor: item.remainingToReturnMinor,
                  ),
                )
                .toList(growable: false),
            pocketBefore: pocketBefore,
            config: config,
            startedAt: DateTime.now(),
          );
      final engine.ChangePlan primaryPlan = returnPreview.plans.firstWhere(
        (engine.ChangePlan plan) => plan.passengerId == record.id,
        orElse: () => engine.ChangePlan.empty,
      );
      final Map<int, int> suggestedPlan = _mapPlanItems(primaryPlan.items);
      return _SettlementEvaluation(
        preview: SettlementPreview(
          recordId: record.id,
          direction: SettlementDirection.returnChange,
          receivedNowDenominationsMinor: const <int>[],
          returnedNowDenominationsMinor: const <int>[],
          appliedReceivedMinor: 0,
          appliedReturnedMinor: 0,
          remainingToCollectMinorAfter: 0,
          remainingToReturnMinorAfter: record.remainingToReturnMinor,
          statusAfter: _statusForRemaining(
            record: record,
            appliedNow: false,
            remainingToCollectMinor: 0,
            remainingToReturnMinor: record.remainingToReturnMinor,
          ),
          feasible: true,
          currentSuggestedPlan: suggestedPlan,
          currentAlternativePlans: const <Map<int, int>>[],
          warnings: <String>[
            ...returnPreview.warnings,
            if (primaryPlan.note != null && primaryPlan.note!.isNotEmpty)
              primaryPlan.note!,
            'الخطة دي محسوبة مع باقي التسويات المفتوحة الحالية.',
          ],
          note: primaryPlan.status == engine.ChangeStatus.infeasible
              ? 'التسوية لسه مش متاحة بالفكة الحالية.'
              : 'تقدر تسويها دلوقتي.',
        ),
        pocketAfter: returnPreview.pocketAfter,
      );
    }

    final int appliedReturnedMinor = _sumDenominations(
      returnedNowDenominationsMinor,
    );
    if (appliedReturnedMinor > record.remainingToReturnMinor) {
      return _SettlementEvaluation(
        preview: SettlementPreview(
          recordId: record.id,
          direction: SettlementDirection.returnChange,
          receivedNowDenominationsMinor: const <int>[],
          returnedNowDenominationsMinor: returnedNowDenominationsMinor,
          appliedReceivedMinor: 0,
          appliedReturnedMinor: appliedReturnedMinor,
          remainingToCollectMinorAfter: 0,
          remainingToReturnMinorAfter: record.remainingToReturnMinor,
          statusAfter: record.settlementStatus,
          feasible: false,
          invalidReason: 'مينفعش ترجع أكتر من الباقي المطلوب.',
        ),
        pocketAfter: pocketBefore,
      );
    }

    final Map<int, int> returnedCounts = _countDenominations(
      returnedNowDenominationsMinor,
    );
    final List<engine.ChangeItem> returnedItems = _toChangeItems(
      returnedCounts,
    );
    if (pocketModeEnabled && !pocketBefore.canPay(returnedItems)) {
      return _SettlementEvaluation(
        preview: SettlementPreview(
          recordId: record.id,
          direction: SettlementDirection.returnChange,
          receivedNowDenominationsMinor: const <int>[],
          returnedNowDenominationsMinor: returnedNowDenominationsMinor,
          appliedReceivedMinor: 0,
          appliedReturnedMinor: appliedReturnedMinor,
          remainingToCollectMinorAfter: 0,
          remainingToReturnMinorAfter: record.remainingToReturnMinor,
          statusAfter: record.settlementStatus,
          feasible: false,
          invalidReason: 'الفئات دي مش موجودة في الفكة الحالية.',
        ),
        pocketAfter: pocketBefore,
      );
    }

    final engine.PocketInventory pocketAfterManual = pocketModeEnabled
        ? pocketBefore.applyChange(returnedItems)
        : pocketBefore;
    final int remainingToReturnMinorAfter =
        record.remainingToReturnMinor - appliedReturnedMinor;

    if (remainingToReturnMinorAfter == 0) {
      return _SettlementEvaluation(
        preview: SettlementPreview(
          recordId: record.id,
          direction: SettlementDirection.returnChange,
          receivedNowDenominationsMinor: const <int>[],
          returnedNowDenominationsMinor: returnedNowDenominationsMinor,
          appliedReceivedMinor: 0,
          appliedReturnedMinor: appliedReturnedMinor,
          remainingToCollectMinorAfter: 0,
          remainingToReturnMinorAfter: 0,
          statusAfter: SettlementStatus.settled,
          feasible: true,
          note: 'تمت التسوية بالكامل.',
        ),
        pocketAfter: pocketAfterManual,
      );
    }

    final engine.BatchAllocationResult remainingPreview = pocketModeEnabled
        ? engineFacade.previewReturnOnly(
            returnMinor: remainingToReturnMinorAfter,
            pocketBefore: pocketAfterManual,
            config: config,
            startedAt: DateTime.now(),
          )
        : engine.BatchAllocationResult(
            modeUsed: engine.EngineMode.fastGreedy,
            plans: const <engine.ChangePlan>[engine.ChangePlan.empty],
            pocketAfter: pocketAfterManual,
            warnings: const <String>[
              'فعّل الفكة علشان تعرف إذا كانت التسوية الباقية ممكنة دلوقتي.',
            ],
            latencyMs: 0,
          );
    final engine.ChangePlan primaryPlan = remainingPreview.plans.first;
    return _SettlementEvaluation(
      preview: SettlementPreview(
        recordId: record.id,
        direction: SettlementDirection.returnChange,
        receivedNowDenominationsMinor: const <int>[],
        returnedNowDenominationsMinor: returnedNowDenominationsMinor,
        appliedReceivedMinor: 0,
        appliedReturnedMinor: appliedReturnedMinor,
        remainingToCollectMinorAfter: 0,
        remainingToReturnMinorAfter: remainingToReturnMinorAfter,
        statusAfter: _statusForRemaining(
          record: record,
          appliedNow: true,
          remainingToCollectMinor: 0,
          remainingToReturnMinor: remainingToReturnMinorAfter,
        ),
        feasible: true,
        currentSuggestedPlan: _mapPlanItems(primaryPlan.items),
        currentAlternativePlans: remainingPreview.plans
            .skip(1)
            .map((engine.ChangePlan plan) => _mapPlanItems(plan.items))
            .where((Map<int, int> plan) => plan.isNotEmpty)
            .toList(growable: false),
        warnings: <String>[
          ...remainingPreview.warnings,
          if (primaryPlan.note != null && primaryPlan.note!.isNotEmpty)
            primaryPlan.note!,
        ],
        note: 'تمت تسوية جزء من الباقي ولسه فيه مبلغ مفتوح.',
      ),
      pocketAfter: pocketAfterManual,
    );
  }

  TransactionRecord? _findRecord(String recordId) {
    try {
      return _repo.load().firstWhere(
        (TransactionRecord record) => record.id == recordId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _persistCommit({
    required PendingCommit commit,
    required String failureMessage,
  }) async {
    try {
      await _pendingCommitRepo.save(commit);
      await _repo.saveAll(commit.records);
      if (commit.pocketModeEnabled && commit.pocketAfter != null) {
        await ref
            .read(pocketProvider.notifier)
            .replaceInventory(commit.pocketAfter!);
      }
      await _pendingCommitRepo.clear();
      return true;
    } catch (_) {
      state = state.copyWith(snackMessage: failureMessage);
      return false;
    }
  }

  void _refreshTransactions() {
    ref.read(transactionsRefreshProvider.notifier).state++;
  }
}

TransactionResult _mapEnginePreviewToTransactionResult(
  engine.BatchAllocationResult preview,
) {
  final engine.ChangePlan primaryPlan = preview.plans.first;
  final Map<int, int> primaryItems = _mapPlanItems(primaryPlan.items);
  final List<Map<int, int>> alternativePlanItems =
      primaryPlan.status == engine.ChangeStatus.underpaid
      ? const <Map<int, int>>[]
      : preview.plans
            .skip(1)
            .map((engine.ChangePlan plan) => _mapPlanItems(plan.items))
            .where((Map<int, int> items) => items.isNotEmpty)
            .toList(growable: false);
  final List<String> warnings = preview.warnings.toSet().toList(
    growable: false,
  );
  final Map<int, int> bestChangePlanItems =
      primaryPlan.status == engine.ChangeStatus.underpaid
      ? const <int, int>{}
      : primaryItems;
  final Map<int, int> completionPlanItems =
      primaryPlan.status == engine.ChangeStatus.underpaid
      ? primaryItems
      : const <int, int>{};

  return TransactionResult(
    totalDueMinor: primaryPlan.dueMinor,
    changeDueMinor: primaryPlan.changeDueMinor,
    status: switch (primaryPlan.status) {
      engine.ChangeStatus.underpaid => TransactionStatus.amountStillOwed,
      engine.ChangeStatus.infeasible => TransactionStatus.changeDue,
      _ =>
        primaryPlan.changeDueMinor == 0
            ? TransactionStatus.exact
            : TransactionStatus.changeDue,
    },
    engineStatus: primaryPlan.status.name,
    bestChangePlanItems: bestChangePlanItems,
    explanation: _buildExplanation(primaryPlan),
    modeUsed: preview.modeUsed.name,
    feasible: primaryPlan.status != engine.ChangeStatus.infeasible,
    alternativePlanItems: alternativePlanItems,
    completionPlanItems: completionPlanItems,
    warnings: warnings,
    infeasibleReason: primaryPlan.status == engine.ChangeStatus.infeasible
        ? (primaryPlan.note ??
              (warnings.isEmpty ? 'مفيش فكة كفاية دلوقتي.' : warnings.first))
        : null,
    note: primaryPlan.note,
  );
}

String _buildExplanation(engine.ChangePlan plan) {
  if (plan.status == engine.ChangeStatus.underpaid) {
    return 'المطلوب ${formatMoneyMinor(plan.dueMinor)} - المدفوع ${formatMoneyMinor(plan.paidMinor)} - باقي عليه ${formatMoneyMinor(plan.changeDueMinor.abs())}';
  }

  if (plan.changeDueMinor == 0) {
    return 'تمام بدون باقي.';
  }

  if (plan.items.isEmpty) {
    return plan.note ?? 'مفيش فكة كفاية دلوقتي.';
  }

  return 'الباقي ${formatMoneyMinor(plan.changeDueMinor)} بخطة صرف دقيقة.';
}

class _DraftEvaluation {
  const _DraftEvaluation({required this.preview, required this.result});

  final engine.BatchAllocationResult preview;
  final TransactionResult result;
}

class _SettlementEvaluation {
  const _SettlementEvaluation({
    required this.preview,
    required this.pocketAfter,
  });

  final SettlementPreview preview;
  final engine.PocketInventory pocketAfter;
}

class _InitialSettlementState {
  const _InitialSettlementState({
    required this.status,
    required this.direction,
    required this.remainingToCollectMinor,
    required this.remainingToReturnMinor,
  });

  final SettlementStatus status;
  final SettlementDirection? direction;
  final int remainingToCollectMinor;
  final int remainingToReturnMinor;
}

_InitialSettlementState _initialSettlementState({
  required TransactionResult result,
}) {
  if (result.status == TransactionStatus.amountStillOwed) {
    return _InitialSettlementState(
      status: SettlementStatus.open,
      direction: SettlementDirection.collectMore,
      remainingToCollectMinor: result.changeDueMinor.abs(),
      remainingToReturnMinor: 0,
    );
  }

  if (result.changeDueMinor > 0 && !result.feasible) {
    return _InitialSettlementState(
      status: SettlementStatus.open,
      direction: SettlementDirection.returnChange,
      remainingToCollectMinor: 0,
      remainingToReturnMinor: result.changeDueMinor,
    );
  }

  return const _InitialSettlementState(
    status: SettlementStatus.settled,
    direction: null,
    remainingToCollectMinor: 0,
    remainingToReturnMinor: 0,
  );
}

SettlementStatus _statusForRemaining({
  required TransactionRecord record,
  required bool appliedNow,
  required int remainingToCollectMinor,
  required int remainingToReturnMinor,
}) {
  if (remainingToCollectMinor == 0 && remainingToReturnMinor == 0) {
    return SettlementStatus.settled;
  }

  if (record.settlementEvents.isNotEmpty || appliedNow) {
    return SettlementStatus.partiallySettled;
  }

  return SettlementStatus.open;
}

bool _nextFeasible({
  required int remainingToCollectMinor,
  required int remainingToReturnMinor,
  required bool hasSuggestedPlan,
}) {
  if (remainingToCollectMinor > 0) {
    return true;
  }

  if (remainingToReturnMinor > 0) {
    return hasSuggestedPlan;
  }

  return true;
}

String _nextChangeStatus({
  required int remainingToCollectMinor,
  required int remainingToReturnMinor,
  required bool hasSuggestedPlan,
}) {
  if (remainingToCollectMinor > 0) {
    return engine.ChangeStatus.underpaid.name;
  }

  if (remainingToReturnMinor > 0) {
    return hasSuggestedPlan
        ? engine.ChangeStatus.exact.name
        : engine.ChangeStatus.infeasible.name;
  }

  return engine.ChangeStatus.exact.name;
}

Map<int, int> _mapPlanItems(List<engine.ChangeItem> items) {
  return <int, int>{
    for (final engine.ChangeItem item in items) item.denomMinor: item.count,
  };
}

int _sumDenominations(List<int> denominationsMinor) {
  return denominationsMinor.fold<int>(
    0,
    (int sum, int denominationMinor) => sum + denominationMinor,
  );
}

Map<int, int> _countDenominations(List<int> denominationsMinor) {
  final Map<int, int> counts = <int, int>{};
  for (final int denominationMinor in denominationsMinor) {
    counts.update(
      denominationMinor,
      (int value) => value + 1,
      ifAbsent: () => 1,
    );
  }
  return counts;
}

List<engine.ChangeItem> _toChangeItems(Map<int, int> counts) {
  final List<int> denoms = counts.keys.toList()
    ..sort((int a, int b) => b.compareTo(a));
  return denoms
      .map((int denom) => engine.ChangeItem(denom, counts[denom]!))
      .toList(growable: false);
}

List<int> _expandDenominationCounts(Map<int, int> counts) {
  final List<int> denoms = counts.keys.toList()
    ..sort((int a, int b) => b.compareTo(a));
  final List<int> expanded = <int>[];
  for (final int denom in denoms) {
    for (int index = 0; index < (counts[denom] ?? 0); index++) {
      expanded.add(denom);
    }
  }
  return expanded;
}
