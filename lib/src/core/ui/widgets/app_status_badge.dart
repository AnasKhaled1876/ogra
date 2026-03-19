import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_theme.dart';

enum AppStatusTone { success, info, warning, error }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({required this.label, required this.tone, super.key});

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final _BadgePalette palette = switch (tone) {
      AppStatusTone.success => _BadgePalette(
        tokens.success,
        AppColors.bgPrimary,
      ),
      AppStatusTone.info => _BadgePalette(tokens.info, AppColors.textPrimary),
      AppStatusTone.warning => _BadgePalette(
        tokens.warning,
        AppColors.bgPrimary,
      ),
      AppStatusTone.error => _BadgePalette(tokens.error, AppColors.textPrimary),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: palette.background.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: palette.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BadgePalette {
  const _BadgePalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}
