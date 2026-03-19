import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/denominations.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_sheet_container.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/pocket_controller.dart';

class PocketSheet extends ConsumerWidget {
  const PocketSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pocket = ref.watch(pocketProvider);
    final settings = ref.watch(settingsProvider);
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return AppSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('الفكة', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'الاقتراحات هتتحسب من الفكة اللي معاك فعليًا.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile.adaptive(
            value: settings.pocketModeEnabled,
            contentPadding: EdgeInsets.zero,
            title: const Text('تفعيل Pocket Mode'),
            subtitle: Text(
              settings.pocketModeEnabled
                  ? 'المعاينة والحساب هيتبنوا على الفكة الحالية.'
                  : 'الحساب هيبقى رياضي فقط من غير قيود فكة.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
            ),
            onChanged: (bool value) {
              ref.read(settingsProvider.notifier).setPocketModeEnabled(value);
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ref.read(pocketProvider.notifier).seedMostlySmallChange();
              },
              child: const Text('بداية وردية'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...kDenominationsMinor.map((int denominationMinor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${formatDenominationLabel(denominationMinor)} جنيه',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref
                          .read(pocketProvider.notifier)
                          .changeCount(denominationMinor, -1);
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    alignment: Alignment.center,
                    child: Text(
                      '${pocket.counts[denominationMinor] ?? 0}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref
                          .read(pocketProvider.notifier)
                          .changeCount(denominationMinor, 1);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
