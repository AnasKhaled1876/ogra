import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/app_spacing.dart';
import '../../../core/ui/app_theme.dart';
import '../../../core/ui/widgets/app_page_header.dart';
import '../../../core/ui/widgets/app_section_card.dart';
import '../../../core/utils/money_formatter.dart';
import '../../settings/application/settings_controller.dart';
import '../application/reports_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final reports = ref.watch(reportsProvider);
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const AppPageHeader(
          title: 'المزيد',
          subtitle: 'إعدادات التشغيل وملخص اليوم في مكان واحد.',
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('الإعدادات', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تفعيل وضع الفكة'),
                subtitle: Text(
                  'خلي الحسابات تراعي الفكة الموجودة فعلياً.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                ),
                value: settings.pocketModeEnabled,
                onChanged: (bool value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setPocketModeEnabled(value);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('أزرار كبيرة'),
                subtitle: Text(
                  'مناسبة للتحصيل السريع أثناء الحركة.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens.textMuted),
                ),
                value: settings.largeButtons,
                onChanged: (bool value) {
                  ref.read(settingsProvider.notifier).setLargeButtons(value);
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'الأجرة الافتراضية',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setDefaultFareMinor(
                              settings.defaultFareMinor - 100,
                            );
                      },
                      child: const Text('-1'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    flex: 2,
                    child: Text(
                      formatMoneyMinor(settings.defaultFareMinor),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setDefaultFareMinor(
                              settings.defaultFareMinor + 100,
                            );
                      },
                      child: const Text('+1'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'تقارير اليوم',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (reports.isEmpty)
                Text(
                  'لسه مفيش عمليات متسجلة.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...<Widget>[
                Text('عدد العمليات: ${reports.first.transactionCount}'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'إجمالي المدفوع: ${formatMoneyMinor(reports.first.collectedMinor)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'إجمالي الفكة الخارجة: ${formatMoneyMinor(reports.first.changeGivenMinor)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('مرات عدم توفر الفكة: ${reports.first.infeasibleCount}'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
