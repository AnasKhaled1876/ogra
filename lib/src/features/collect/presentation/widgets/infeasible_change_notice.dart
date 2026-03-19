import 'package:flutter/material.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';

class InfeasibleChangeNotice extends StatelessWidget {
  const InfeasibleChangeNotice({
    required this.reason,
    required this.statusColors,
    super.key,
  });

  final String reason;
  final OgraUiTokens statusColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: statusColors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: statusColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: statusColors.warning),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'الفكة غير متاحة',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: statusColors.warning),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reason,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: statusColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'جرب ورقة أصغر أو سجّلها كتسوية مفتوحة.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: statusColors.warning),
          ),
        ],
      ),
    );
  }
}
