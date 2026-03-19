import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/denominations.dart';
import '../../../core/ui/app_spacing.dart';
import '../../../core/ui/widgets/app_page_header.dart';
import '../../../core/ui/widgets/app_section_card.dart';
import '../../../core/utils/money_formatter.dart';
import '../application/pocket_controller.dart';

class PocketScreen extends ConsumerWidget {
  const PocketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pocket = ref.watch(pocketProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const AppPageHeader(
          title: 'الفكة',
          subtitle: 'إدارة سريعة للفكة اللي معاك علشان الاقتراحات تبقى واقعية.',
        ),
        const SizedBox(height: AppSpacing.md),
        AppSectionCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(pocketProvider.notifier)
                            .seedMostlySmallChange();
                      },
                      child: const Text('بداية وردية'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ...kDenominationsMinor.map((int denomination) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          formatMoneyMinor(denomination),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref
                              .read(pocketProvider.notifier)
                              .changeCount(denomination, -1);
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 36),
                        alignment: Alignment.center,
                        child: Text(
                          '${pocket.counts[denomination] ?? 0}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ref
                              .read(pocketProvider.notifier)
                              .changeCount(denomination, 1);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
