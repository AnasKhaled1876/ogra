import 'package:flutter/material.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_icon_container.dart';
import '../../../../core/ui/widgets/app_sheet_container.dart';
import '../../domain/transaction_record.dart';
import '../helpers/received_money_formatter.dart';
import '../helpers/transaction_action_suggestions.dart';

class TransactionActionsSheet extends StatelessWidget {
  const TransactionActionsSheet({required this.record, super.key});

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    final List<TransactionActionSuggestion> suggestions =
        buildEgyptianCurrencyActionSuggestions(record);
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final bool isFareComplete = record.isSettled && record.changeDueMinor == 0;

    return AppSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _phraseFor(record),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isFareComplete
                ? 'الحساب مكتمل للراكب ده.'
                : 'اقتراحات سريعة تقدر تقولها للراكب دلوقتي.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isFareComplete)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: tokens.elevatedSurface,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Text(
                'الأجرة مكتملة، ومافيش باقي أو مبلغ ناقص على الراكب ده.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
              ),
            )
          else
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SuggestionTile(suggestion: suggestion),
              );
            }),
        ],
      ),
    );
  }

  String _phraseFor(TransactionRecord record) {
    return '${record.ridersCount} من ${formatReceivedDenominations(record.receivedDenominationsMinor)}';
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion});

  final TransactionActionSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppIconContainer(icon: suggestion.icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  suggestion.body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
