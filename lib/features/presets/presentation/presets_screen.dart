import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/app_spacing.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/ui/widgets/app_icon_container.dart';
import '../../../core/ui/widgets/app_page_header.dart';
import '../../../core/ui/widgets/app_section_card.dart';
import '../../../core/utils/money_formatter.dart';
import '../../collect/application/collect_controller.dart';
import '../application/presets_controller.dart';
import '../domain/fare_preset.dart';

class PresetsScreen extends ConsumerWidget {
  const PresetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<FarePreset> presets = ref.watch(presetsProvider);
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const AppPageHeader(
          title: 'الاختصارات',
          subtitle: 'قوالب جاهزة للعبارات الشائعة وقت التحصيل.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...presets.map((FarePreset preset) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppSectionCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: ListTile(
                title: Text(
                  preset.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    'الأجرة ${formatMoneyMinor(preset.fareMinor)} - ${preset.ridersCount} ركاب - المدفوع ${formatMoneyMinor(preset.amountPaidMinor)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                trailing: const AppIconContainer(
                  icon: Icons.chevron_left_rounded,
                  size: 36,
                ),
                onTap: () {
                  ref
                      .read(collectProvider.notifier)
                      .applyPreset(
                        fareMinor: preset.fareMinor,
                        ridersCount: preset.ridersCount,
                        amountPaidMinor: preset.amountPaidMinor,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحميل الاختصار في شاشة التحصيل.'),
                    ),
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
