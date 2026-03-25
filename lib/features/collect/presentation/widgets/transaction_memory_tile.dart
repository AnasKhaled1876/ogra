import 'package:flutter/material.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';

class TransactionMemoryTile extends StatelessWidget {
  const TransactionMemoryTile({
    required this.phrase,
    required this.footer,
    required this.onTap,
    required this.onDelete,
    super.key,
    this.notesLine,
  });

  final String phrase;
  final String? notesLine;
  final Widget footer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: tokens.elevatedSurface,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: tokens.borderSubtle, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      phrase,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    splashRadius: 18,
                    icon: Icon(
                      Icons.delete_outline,
                      color: tokens.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (notesLine != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  notesLine!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: tokens.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxs),
              footer,
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionDeleteBackground extends StatelessWidget {
  const TransactionDeleteBackground({required this.alignment, super.key});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.error.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: tokens.error.withValues(alpha: 0.4)),
      ),
      child: Icon(Icons.delete_outline, color: tokens.error),
    );
  }
}
