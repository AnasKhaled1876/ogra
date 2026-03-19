import 'package:flutter/material.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../domain/transaction_record.dart';

class TransactionActionSuggestion {
  const TransactionActionSuggestion({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

List<TransactionActionSuggestion> buildEgyptianCurrencyActionSuggestions(
  TransactionRecord record,
) {
  if (record.manualOverride) {
    return <TransactionActionSuggestion>[
      TransactionActionSuggestion(
        icon: Icons.rule_folder_outlined,
        title: 'تجاوز يدوي',
        body:
            record.engineNote ?? 'تم تسجيل العملية يدويًا بدون خطة صرف محفوظة.',
      ),
    ];
  }

  if (record.changeDueMinor == 0) {
    return const <TransactionActionSuggestion>[];
  }

  final List<TransactionActionSuggestion> suggestions =
      <TransactionActionSuggestion>[];

  if (record.changePlanItems.isNotEmpty) {
    suggestions.add(
      TransactionActionSuggestion(
        icon: Icons.assignment_return_outlined,
        title: 'رجّع له الباقي كده',
        body:
            'الباقي ${formatMoneyMinor(record.changeDueMinor)}: ${_formatPlan(record.changePlanItems)}.',
      ),
    );
  }

  for (int index = 0; index < record.alternativePlanItems.length; index++) {
    final Map<int, int> plan = record.alternativePlanItems[index];
    suggestions.add(
      TransactionActionSuggestion(
        icon: Icons.alt_route_outlined,
        title: index == 0 ? 'بديل للصرف' : 'بديل إضافي',
        body: _formatPlan(plan),
      ),
    );
  }

  if (record.completionPlanItems.isNotEmpty) {
    suggestions.add(
      TransactionActionSuggestion(
        icon: Icons.add_card_outlined,
        title: 'خليه يكملها كده',
        body: _formatPlan(record.completionPlanItems),
      ),
    );
  }

  for (final String warning in record.engineWarnings) {
    suggestions.add(
      TransactionActionSuggestion(
        icon: Icons.info_outline,
        title: 'تنبيه',
        body: warning,
      ),
    );
  }

  if (suggestions.isEmpty &&
      record.engineNote != null &&
      !record.engineWarnings.contains(record.engineNote)) {
    suggestions.add(
      TransactionActionSuggestion(
        icon: Icons.lightbulb_outline,
        title: 'ملاحظة',
        body: record.engineNote!,
      ),
    );
  }

  return suggestions;
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
