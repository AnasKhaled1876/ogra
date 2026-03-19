import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/app_radius.dart';
import '../../../core/ui/app_spacing.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../application/collect_controller.dart';
import '../application/collect_state.dart';
import '../application/open_settlement_view.dart';
import '../domain/transaction_record.dart';
import '../../pocket/presentation/sheets/pocket_sheet.dart';
import '../../settings/application/settings_controller.dart';
import 'sheets/fare_edit_sheet.dart';
import 'sheets/settlement_sheet.dart';
import 'sheets/transaction_sheet.dart';
import 'helpers/received_money_formatter.dart';
import 'widgets/fare_card.dart';
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
      if (message == null || message == previous?.snackMessage) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

      ref.read(collectProvider.notifier).clearSnackMessage();
    });

    final CollectState state = ref.watch(collectProvider);
    final List<OpenSettlementView> openSettlements = ref.watch(
      openSettlementsProvider,
    );
    final List<TransactionRecord> transactions = ref.watch(
      settledTransactionsProvider,
    );
    final bool pocketModeEnabled = ref.watch(
      settingsProvider.select((settings) => settings.pocketModeEnabled),
    );
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100,
        ),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'أجرة',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(color: scheme.primary, height: 1),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'رفيق المشوار',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'الفكة',
                onPressed: () => _openPocketSheet(context),
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
              const SizedBox(width: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: () => _startNewTrip(context, ref, state.fareMinor),
                icon: Icon(Icons.add, color: scheme.primary),
                iconAlignment: IconAlignment.end,
                label: Text(
                  'رحلة جديدة',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  backgroundColor: scheme.primary.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.small),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FareCard(fareMinor: state.fareMinor),
          const SizedBox(height: AppSpacing.xl),
          if (openSettlements.isNotEmpty) ...<Widget>[
            OpenSettlementsCard(items: openSettlements),
            const SizedBox(height: AppSpacing.xl),
          ],
          TripTransactionsCard(
            records: transactions,
            onAddTransaction: () => _openTransactionSheet(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTransactionSheet(context, ref),
        tooltip: 'عملية جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _startNewTrip(
    BuildContext context,
    WidgetRef ref,
    int currentFareMinor,
  ) async {
    await ref.read(collectProvider.notifier).startNewTrip();
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (BuildContext context) {
        return FareEditSheet(currentFareMinor: currentFareMinor);
      },
    );
  }

  Future<void> _openTransactionSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    ref.read(collectProvider.notifier).startDraft();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return const TransactionSheet();
      },
    );
    ref.read(collectProvider.notifier).resetDraft();
    final List<OpenSettlementView> newlyResolvableSettlements = ref
        .read(collectProvider)
        .newlyResolvableSettlements;
    if (newlyResolvableSettlements.isEmpty || !context.mounted) {
      return;
    }
    ref.read(collectProvider.notifier).clearNewlyResolvableSettlements();
    await _showNewlyResolvableSettlementsDialog(
      context,
      newlyResolvableSettlements,
    );
  }

  Future<void> _openPocketSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext context) {
        return const PocketSheet();
      },
    );
  }

  Future<void> _showNewlyResolvableSettlementsDialog(
    BuildContext context,
    List<OpenSettlementView> items,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('تسويات جاهزة دلوقتي'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('العملية الأخيرة خلت التسويات دي قابلة للتسوية الآن.'),
              const SizedBox(height: AppSpacing.md),
              ...items.map((OpenSettlementView item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    onTap: () async {
                      Navigator.of(dialogContext).pop();
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (BuildContext context) {
                          return SettlementSheet(recordId: item.record.id);
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${item.record.ridersCount} من ${formatReceivedDenominations(item.record.receivedDenominationsMinor)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            item.record.remainingToReturnMinor > 0
                                ? 'باقي ليه ${formatMoneyMinor(item.record.remainingToReturnMinor)}'
                                : 'باقي عليه ${formatMoneyMinor(item.record.remainingToCollectMinor)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('بعد شوية'),
            ),
          ],
        );
      },
    );
  }
}
