import 'package:flutter/material.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';

class TransactionRidersSelector extends StatelessWidget {
  const TransactionRidersSelector({
    required this.selectedRidersCount,
    required this.onSelected,
    super.key,
  });

  final int selectedRidersCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'عدد الركاب',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: List<Widget>.generate(6, (int index) {
            final int value = index + 1;
            final bool isSelected = selectedRidersCount == value;

            return Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: index == 0 ? 0 : AppSpacing.xs,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  onTap: () => onSelected(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 58,
                    decoration: BoxDecoration(
                      color: isSelected ? scheme.primary : tokens.inputSurface,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(
                        color: isSelected
                            ? scheme.primary
                            : tokens.borderAccent,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$value',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? scheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
