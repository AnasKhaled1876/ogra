import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_section_card.dart';
import '../sheets/fare_edit_sheet.dart';

class FareCard extends ConsumerWidget {
  const FareCard({required this.fareMinor, super.key});

  final int fareMinor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return AppSectionCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'الأجرة',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                RichText(
                  text: TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: '${fareMinor ~/ 100}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 24,
                            ),
                      ),
                      TextSpan(
                        text: ' جنيه',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: tokens.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          TextButton(
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                builder: (BuildContext context) {
                  return FareEditSheet(currentFareMinor: fareMinor);
                },
              );
            },
            child: Text(
              'تعديل',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
