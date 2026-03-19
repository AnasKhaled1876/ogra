import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../collect/application/collect_controller.dart';
import '../../collect/domain/transaction_record.dart';
import '../domain/daily_aggregate.dart';

final reportsProvider = Provider<List<DailyAggregate>>((Ref ref) {
  final List<TransactionRecord> transactions = ref.watch(transactionsProvider);
  final Map<String, List<TransactionRecord>> grouped =
      <String, List<TransactionRecord>>{};

  for (final TransactionRecord record in transactions) {
    final DateTime day = DateTime(
      record.createdAt.year,
      record.createdAt.month,
      record.createdAt.day,
    );
    final String key = day.toIso8601String();
    grouped.putIfAbsent(key, () => <TransactionRecord>[]);
    grouped[key]!.add(record);
  }

  final List<DailyAggregate> values =
      grouped.entries.map((entry) {
          final List<TransactionRecord> records = entry.value;
          return DailyAggregate(
            day: DateTime.parse(entry.key),
            transactionCount: records.length,
            collectedMinor: records.fold<int>(
              0,
              (int sum, TransactionRecord record) =>
                  sum + record.amountPaidMinor,
            ),
            changeGivenMinor: records.fold<int>(
              0,
              (int sum, TransactionRecord record) =>
                  sum + (record.changeDueMinor > 0 ? record.changeDueMinor : 0),
            ),
            infeasibleCount: records
                .where((TransactionRecord record) => !record.feasible)
                .length,
          );
        }).toList()
        ..sort((DailyAggregate a, DailyAggregate b) => b.day.compareTo(a.day));

  return values;
});
