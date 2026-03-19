import 'package:flutter/material.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/transaction_draft.dart';
import '../../domain/transaction_result.dart';
import '../helpers/received_money_formatter.dart';
import 'infeasible_change_notice.dart';

class TransactionPreviewCard extends StatelessWidget {
  const TransactionPreviewCard({
    required this.draft,
    required this.result,
    required this.statusColors,
    super.key,
  });

  final TransactionDraft draft;
  final TransactionResult result;
  final OgraUiTokens statusColors;

  String? get _planLabel {
    if (result.status == TransactionStatus.exact) {
      return 'بدون صرف.';
    }

    if (result.status == TransactionStatus.amountStillOwed &&
        result.completionPlanItems.isNotEmpty) {
      return 'التكملة: ${_formatPlan(result.completionPlanItems)}';
    }

    if (result.bestChangePlanItems.isNotEmpty) {
      return result.status == TransactionStatus.amountStillOwed
          ? 'التكملة: ${_formatPlan(result.bestChangePlanItems)}'
          : 'خطة الصرف: ${_formatPlan(result.bestChangePlanItems)}';
    }

    return result.note;
  }

  String? get _alternativePlanLabel {
    if (result.alternativePlanItems.isEmpty) {
      return null;
    }

    return 'بديل: ${_formatPlan(result.alternativePlanItems.first)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MetricColumn(
                label: 'المطلوب',
                value: formatMoneyMinor(result.totalDueMinor),
              ),
            ),
            Expanded(
              child: _MetricColumn(
                label: 'المدفوع',
                value: formatMoneyMinor(draft.amountPaidMinor),
              ),
            ),
            Expanded(
              child: _MetricColumn(
                label: result.status == TransactionStatus.amountStillOwed
                    ? 'الباقي عليه'
                    : 'الباقي ليه',
                value: formatMoneyMinor(result.changeDueMinor.abs()),
                highlight: result.status != TransactionStatus.amountStillOwed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'المستلم: ${formatReceivedDenominations(draft.receivedDenominationsMinor)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: statusColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 1,
          decoration: BoxDecoration(
            color: statusColors.borderSubtle,
            borderRadius: BorderRadius.circular(AppRadius.small),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          result.explanation,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: statusColors.textSecondary),
        ),
        if (_planLabel != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _planLabel!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (_alternativePlanLabel != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _alternativePlanLabel!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: statusColors.textSecondary),
          ),
        ],
        if (result.warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          ...result.warnings.map((String warning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Text(
                warning,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColors.textSecondary,
                ),
              ),
            );
          }),
        ],
        if (!result.feasible && result.infeasibleReason != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          InfeasibleChangeNotice(
            reason: result.infeasibleReason!,
            statusColors: statusColors,
          ),
        ],
      ],
    );
  }

  String _formatPlan(Map<int, int> items) {
    final List<int> denoms = items.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return denoms
        .map((int denom) {
          return '${items[denom]} من فئة ${formatDenominationLabel(denom)} جنيه';
        })
        .join(' + ');
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: highlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
