import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../application/collect_controller.dart';
import '../../application/open_settlement_view.dart';
import '../../domain/settlement_models.dart';
import '../helpers/received_money_formatter.dart';
import '../sheets/settlement_sheet.dart';
import 'transaction_memory_tile.dart';

class OpenSettlementsCard extends ConsumerWidget {
  const OpenSettlementsCard({required this.items, super.key});

  final List<OpenSettlementView> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('تسويات مفتوحة', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        ...items.map((OpenSettlementView item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Dismissible(
              key: ValueKey<String>('open_${item.record.id}'),
              direction: DismissDirection.horizontal,
              background: const TransactionDeleteBackground(
                alignment: Alignment.centerLeft,
              ),
              secondaryBackground: const TransactionDeleteBackground(
                alignment: Alignment.centerRight,
              ),
              onDismissed: (_) {
                ref
                    .read(collectProvider.notifier)
                    .deleteTransaction(item.record);
              },
              child: _OpenSettlementTile(
                item: item,
                onDelete: () {
                  ref
                      .read(collectProvider.notifier)
                      .deleteTransaction(item.record);
                },
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (BuildContext context) {
                      return SettlementSheet(recordId: item.record.id);
                    },
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _OpenSettlementTile extends StatelessWidget {
  const _OpenSettlementTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final OpenSettlementView item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final _StatusStyle statusStyle = _statusStyle(
      context,
      item.resolutionState,
    );

    return TransactionMemoryTile(
      phrase: _phraseFor(item),
      notesLine: _paidNotesText(item),
      footer: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              _detailText(item),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: statusStyle.backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusStyle.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusStyle.textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      onTap: onTap,
      onDelete: onDelete,
    );
  }

  String _phraseFor(OpenSettlementView item) {
    return '${item.record.ridersCount} من ${formatDenominationLabel(item.record.amountPaidMinor)}';
  }

  String _paidNotesText(OpenSettlementView item) {
    return 'دفع: ${formatReceivedDenominations(item.record.receivedDenominationsMinor)}';
  }

  String _detailText(OpenSettlementView item) {
    if (item.record.remainingToCollectMinor > 0) {
      return 'باقي عليه ${formatMoneyMinor(item.record.remainingToCollectMinor)}';
    }

    return 'باقي ليه ${formatMoneyMinor(item.record.remainingToReturnMinor)}';
  }

  _StatusStyle _statusStyle(
    BuildContext context,
    SettlementResolutionState state,
  ) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    return switch (state) {
      SettlementResolutionState.waitingOnPassenger => _StatusStyle(
        label: 'ينتظر دفع',
        textColor: tokens.info,
        backgroundColor: tokens.info.withValues(alpha: 0.16),
      ),
      SettlementResolutionState.resolvableNow => _StatusStyle(
        label: 'قابل للتسوية الآن',
        textColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.14),
      ),
      SettlementResolutionState.blocked => _StatusStyle(
        label: 'معلق',
        textColor: tokens.error,
        backgroundColor: tokens.error.withValues(alpha: 0.16),
      ),
    };
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  final String label;
  final Color textColor;
  final Color backgroundColor;
}
