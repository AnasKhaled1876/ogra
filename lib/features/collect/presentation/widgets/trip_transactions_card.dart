import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../application/collect_controller.dart';
import '../../domain/transaction_record.dart';
import '../helpers/received_money_formatter.dart';
import '../sheets/transaction_actions_sheet.dart';
import 'transaction_memory_tile.dart';

class TripTransactionsCard extends ConsumerWidget {
  const TripTransactionsCard({
    required this.records,
    required this.onAddTransaction,
    super.key,
  });

  final List<TransactionRecord> records;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'عمليات الرحلة',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            OutlinedButton.icon(
              onPressed: onAddTransaction,
              icon: Icon(Icons.add, color: scheme.primary),
              iconAlignment: IconAlignment.end,
              label: Text(
                'عملية جديدة',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 42),
                backgroundColor: scheme.primary.withValues(alpha: 0.08),
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: tokens.elevatedSurface,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Text(
              'لسه مفيش عمليات مقفولة في الرحلة دي.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
          )
        else
          ...records.map((TransactionRecord record) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Dismissible(
                key: ValueKey<String>(record.id),
                direction: DismissDirection.horizontal,
                background: const TransactionDeleteBackground(
                  alignment: Alignment.centerLeft,
                ),
                secondaryBackground: const TransactionDeleteBackground(
                  alignment: Alignment.centerRight,
                ),
                onDismissed: (_) {
                  ref.read(collectProvider.notifier).deleteTransaction(record);
                },
                child: _TripTransactionTile(
                  record: record,
                  onDelete: () {
                    ref
                        .read(collectProvider.notifier)
                        .deleteTransaction(record);
                  },
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (BuildContext context) {
                        return TransactionActionsSheet(record: record);
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

class _TripTransactionTile extends StatelessWidget {
  const _TripTransactionTile({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final TransactionRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return TransactionMemoryTile(
      phrase: _phraseFor(record),
      notesLine: _paidNotesText(record),
      footer: _DetailText(record: record),
      onTap: onTap,
      onDelete: onDelete,
    );
  }

  String _phraseFor(TransactionRecord record) {
    return '${record.ridersCount} من ${formatDenominationLabel(record.amountPaidMinor)}';
  }

  String _paidNotesText(TransactionRecord record) {
    return 'دفع: ${formatReceivedDenominations(record.receivedDenominationsMinor)}';
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText({required this.record});

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final TextStyle baseStyle = Theme.of(context).textTheme.titleMedium!
        .copyWith(
          color: tokens.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        );

    final String required = formatMoneyMinor(record.totalDueMinor);
    final InlineSpan trailing = switch (record.changeDueMinor) {
      < 0 => TextSpan(
        text: 'باقي عليه ${formatMoneyMinor(record.changeDueMinor.abs())}',
        style: baseStyle.copyWith(color: tokens.error),
      ),
      0 => TextSpan(
        text: 'بدون باقي',
        style: baseStyle.copyWith(color: tokens.success),
      ),
      _ => TextSpan(
        text: 'باقي ${formatMoneyMinor(record.changeDueMinor)}',
        style: baseStyle.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    };

    return RichText(
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: baseStyle,
        children: <InlineSpan>[
          TextSpan(text: required),
          TextSpan(
            text: ' — ',
            style: baseStyle.copyWith(color: tokens.textMuted),
          ),
          trailing,
        ],
      ),
    );
  }
}
