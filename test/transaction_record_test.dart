import 'package:flutter_test/flutter_test.dart';
import 'package:ogra/features/collect/domain/settlement_models.dart';
import 'package:ogra/features/collect/domain/transaction_record.dart';

void main() {
  test(
    'fromJson backfills a legacy underpaid transaction into an open collect settlement',
    () {
      final TransactionRecord record = TransactionRecord.fromJson(
        <String, dynamic>{
          'id': 'legacy-underpaid',
          'createdAt': '2026-03-18T12:00:00.000',
          'fareMinor': 1500,
          'ridersCount': 2,
          'amountPaidMinor': 2000,
          'totalDueMinor': 3000,
          'changeDueMinor': -1000,
          'changePlanItems': <String, int>{},
          'alternativePlanItems': const <Map<String, int>>[],
          'completionPlanItems': <String, int>{'1000': 1},
          'feasible': true,
          'manualOverride': false,
        },
      );

      expect(record.settlementStatus, SettlementStatus.open);
      expect(record.settlementDirection, SettlementDirection.collectMore);
      expect(record.remainingToCollectMinor, 1000);
      expect(record.remainingToReturnMinor, 0);
      expect(record.isOpen, isTrue);
    },
  );

  test(
    'fromJson backfills a legacy infeasible return into an open return settlement',
    () {
      final TransactionRecord record =
          TransactionRecord.fromJson(<String, dynamic>{
            'id': 'legacy-return',
            'createdAt': '2026-03-18T12:00:00.000',
            'fareMinor': 1500,
            'ridersCount': 1,
            'amountPaidMinor': 2000,
            'totalDueMinor': 1500,
            'changeDueMinor': 500,
            'changePlanItems': <String, int>{},
            'alternativePlanItems': const <Map<String, int>>[],
            'completionPlanItems': <String, int>{},
            'feasible': false,
            'manualOverride': false,
          });

      expect(record.settlementStatus, SettlementStatus.open);
      expect(record.settlementDirection, SettlementDirection.returnChange);
      expect(record.remainingToCollectMinor, 0);
      expect(record.remainingToReturnMinor, 500);
      expect(record.isOpen, isTrue);
    },
  );

  test(
    'fromJson keeps a legacy feasible return settled when no settlement fields exist',
    () {
      final TransactionRecord record = TransactionRecord.fromJson(
        <String, dynamic>{
          'id': 'legacy-settled',
          'createdAt': '2026-03-18T12:00:00.000',
          'fareMinor': 1500,
          'ridersCount': 1,
          'amountPaidMinor': 2000,
          'totalDueMinor': 1500,
          'changeDueMinor': 500,
          'changePlanItems': <String, int>{'500': 1},
          'alternativePlanItems': const <Map<String, int>>[],
          'completionPlanItems': <String, int>{},
          'feasible': true,
          'manualOverride': false,
        },
      );

      expect(record.settlementStatus, SettlementStatus.settled);
      expect(record.settlementDirection, isNull);
      expect(record.remainingToCollectMinor, 0);
      expect(record.remainingToReturnMinor, 0);
      expect(record.isSettled, isTrue);
    },
  );
}
