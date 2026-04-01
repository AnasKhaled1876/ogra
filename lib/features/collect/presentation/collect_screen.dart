import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/app_radius.dart';
import '../../../core/ui/app_spacing.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../application/collect_controller.dart';
import '../application/collect_state.dart';
import '../application/open_settlement_view.dart';
import '../domain/settlement_models.dart';
import '../domain/transaction_record.dart';
import '../../pocket/presentation/sheets/pocket_sheet.dart';
import '../../settings/application/settings_controller.dart';
import 'sheets/fare_edit_sheet.dart';
import 'sheets/settlement_sheet.dart';
import 'sheets/transaction_sheet.dart';
import 'widgets/open_settlements_card.dart';
import 'widgets/trip_transactions_card.dart';

class CollectScreen extends ConsumerWidget {
  const CollectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CollectState>(collectProvider, (
      CollectState? previous,
      CollectState next,
    ) {
      final String? message = next.snackMessage;
      if (message == null || message == previous?.snackMessage) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      ref.read(collectProvider.notifier).clearSnackMessage();
    });

    final CollectState state = ref.watch(collectProvider);
    final List<OpenSettlementView> openSettlements =
        ref.watch(openSettlementsProvider);
    final List<TransactionRecord> transactions =
        ref.watch(settledTransactionsProvider);
    final bool pocketModeEnabled = ref.watch(
      settingsProvider.select((s) => s.pocketModeEnabled),
    );

    final int totalDueMinor = transactions.fold(
      0,
      (int sum, TransactionRecord r) => sum + r.totalDueMinor,
    );

    return Scaffold(
      // ── Zone 1: Status bar ───────────────────────────────────────────────
      appBar: _StatusBar(
        fareMinor: state.fareMinor,
        transactionCount: transactions.length,
        totalDueMinor: totalDueMinor,
        pocketModeEnabled: pocketModeEnabled,
        onFareTap: () => _openFareEdit(context, state.fareMinor),
        onPocketTap: () => _openPocketSheet(context),
      ),

      // ── Zone 3: Scrollable list ──────────────────────────────────────────
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          // Zone 2: Settlement alert — always first when present
          if (openSettlements.isNotEmpty) ...<Widget>[
            _SettlementsBanner(
              items: openSettlements,
              onTap: (String recordId) => _openSettlementSheet(context, recordId),
            ),
            const SizedBox(height: AppSpacing.md),
            OpenSettlementsCard(items: openSettlements),
            const SizedBox(height: AppSpacing.xl),
          ],
          TripTransactionsCard(records: transactions),
        ],
      ),

      // ── Zone 4: Bottom action bar ────────────────────────────────────────
      bottomNavigationBar: _BottomActionBar(
        onNewTransaction: () => _openTransactionSheet(context, ref),
        onNewTrip: () => _startNewTrip(context, ref, state.fareMinor),
      ),
    );
  }

  Future<void> _openFareEdit(BuildContext context, int currentFareMinor) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => FareEditSheet(currentFareMinor: currentFareMinor),
    );
  }

  Future<void> _openPocketSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const PocketSheet(),
    );
  }

  Future<void> _startNewTrip(
    BuildContext context,
    WidgetRef ref,
    int currentFareMinor,
  ) async {
    await ref.read(collectProvider.notifier).startNewTrip();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => FareEditSheet(currentFareMinor: currentFareMinor),
    );
  }

  Future<void> _openTransactionSheet(BuildContext context, WidgetRef ref) async {
    ref.read(collectProvider.notifier).startDraft();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TransactionSheet(),
    );
    ref.read(collectProvider.notifier).resetDraft();
    if (!context.mounted) return;
    final List<OpenSettlementView> newly =
        ref.read(collectProvider).newlyResolvableSettlements;
    if (newly.isEmpty) return;
    ref.read(collectProvider.notifier).clearNewlyResolvableSettlements();
    await _showNewlyResolvableDialog(context, newly);
  }

  Future<void> _openSettlementSheet(BuildContext context, String recordId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SettlementSheet(recordId: recordId),
    );
  }

  Future<void> _showNewlyResolvableDialog(
    BuildContext context,
    List<OpenSettlementView> items,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('تسويات جاهزة دلوقتي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('العملية الأخيرة خلت التسويات دي قابلة للتسوية الآن.'),
              const SizedBox(height: AppSpacing.md),
              ...items.map((OpenSettlementView item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${item.record.ridersCount} من ${formatDenominationLabel(item.record.amountPaidMinor)}',
                  ),
                  subtitle: Text(
                    item.record.remainingToReturnMinor > 0
                        ? 'باقي ليه ${formatMoneyMinor(item.record.remainingToReturnMinor)}'
                        : 'باقي عليه ${formatMoneyMinor(item.record.remainingToCollectMinor)}',
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _openSettlementSheet(context, item.record.id);
                  },
                );
              }),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('بعد شوية'),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone 1 — Status bar (replaces the old branding header)
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget implements PreferredSizeWidget {
  const _StatusBar({
    required this.fareMinor,
    required this.transactionCount,
    required this.totalDueMinor,
    required this.pocketModeEnabled,
    required this.onFareTap,
    required this.onPocketTap,
  });

  final int fareMinor;
  final int transactionCount;
  final int totalDueMinor;
  final bool pocketModeEnabled;
  final VoidCallback onFareTap;
  final VoidCallback onPocketTap;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: <Widget>[
                // Fare — primary info, tappable to edit
                Expanded(
                  child: GestureDetector(
                    onTap: onFareTap,
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          '${fareMinor ~/ 100}',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontSize: 36, height: 1),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'جنيه',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: tokens.textSecondary),
                            ),
                            Text(
                              'الأجرة',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: tokens.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: tokens.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                // Trip stats
                if (transactionCount > 0) ...<Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '$transactionCount ${transactionCount == 1 ? 'عملية' : 'عمليات'}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                      Text(
                        formatMoneyMinor(totalDueMinor),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],

                // Pocket toggle
                IconButton(
                  tooltip: 'الفكة',
                  onPressed: onPocketTap,
                  style: IconButton.styleFrom(
                    backgroundColor: pocketModeEnabled
                        ? scheme.primary.withValues(alpha: 0.14)
                        : tokens.elevatedSurface,
                    foregroundColor: pocketModeEnabled
                        ? scheme.primary
                        : tokens.textSecondary,
                  ),
                  icon: Icon(
                    pocketModeEnabled
                        ? Icons.account_balance_wallet
                        : Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone 2 — Settlements urgent banner
// ─────────────────────────────────────────────────────────────────────────────

class _SettlementsBanner extends StatelessWidget {
  const _SettlementsBanner({
    required this.items,
    required this.onTap,
  });

  final List<OpenSettlementView> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    // Count how many need immediate action
    final int urgent = items
        .where((OpenSettlementView i) =>
            i.resolutionState == SettlementResolutionState.resolvableNow)
        .length;

    final String label = urgent > 0
        ? '$urgent ${urgent == 1 ? 'تسوية جاهزة' : 'تسويات جاهزة'} — اضغط للتسوية'
        : '${items.length} ${items.length == 1 ? 'تسوية مفتوحة' : 'تسويات مفتوحة'}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: items.length == 1 ? () => onTap(items.first.record.id) : null,
        child: Ink(
          decoration: BoxDecoration(
            color: urgent > 0
                ? tokens.warning.withValues(alpha: 0.14)
                : tokens.elevatedSurface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: urgent > 0
                  ? tokens.warning.withValues(alpha: 0.5)
                  : tokens.borderSubtle,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                urgent > 0
                    ? Icons.warning_amber_rounded
                    : Icons.hourglass_empty_rounded,
                color: urgent > 0 ? tokens.warning : tokens.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: urgent > 0 ? tokens.warning : tokens.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: urgent > 0
                    ? tokens.warning.withValues(alpha: 0.7)
                    : tokens.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zone 4 — Bottom action bar (replaces FAB)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onNewTransaction,
    required this.onNewTrip,
  });

  final VoidCallback onNewTransaction;
  final VoidCallback onNewTrip;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              // Secondary — new trip (smaller, right side in RTL)
              OutlinedButton(
                onPressed: onNewTrip,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                child: const Text('رحلة جديدة'),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Primary — new transaction (wide, left side in RTL = thumb reach)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNewTransaction,
                  icon: const Icon(Icons.add, size: 20),
                  iconAlignment: IconAlignment.end,
                  label: const Text('عملية جديدة'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 54),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
