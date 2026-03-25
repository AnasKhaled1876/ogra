import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ogra/features/collect/domain/settlement_models.dart';
import 'package:ogra/features/collect/domain/transaction_record.dart';
import 'package:ogra/features/collect/presentation/helpers/transaction_action_suggestions.dart';

TransactionRecord _record({
  required int changeDueMinor,
  required String changeStatus,
  Map<int, int> changePlanItems = const <int, int>{},
  List<Map<int, int>> alternativePlanItems = const <Map<int, int>>[],
  Map<int, int> completionPlanItems = const <int, int>{},
  bool manualOverride = false,
  String? engineNote,
  List<String> engineWarnings = const <String>[],
}) {
  final SettlementDirection? settlementDirection = changeDueMinor < 0
      ? SettlementDirection.collectMore
      : changeDueMinor > 0 && (manualOverride || changeStatus == 'infeasible')
      ? SettlementDirection.returnChange
      : null;
  return TransactionRecord(
    id: '1',
    createdAt: DateTime(2026, 3, 18),
    fareMinor: 1500,
    ridersCount: 1,
    receivedDenominationsMinor: const <int>[2000],
    amountPaidMinor: 2000,
    totalDueMinor: 1500,
    changeDueMinor: changeDueMinor,
    changePlanItems: changePlanItems,
    alternativePlanItems: alternativePlanItems,
    completionPlanItems: completionPlanItems,
    feasible: changeStatus != 'infeasible',
    manualOverride: manualOverride,
    engineModeUsed: 'smartDp',
    changeStatus: changeStatus,
    engineWarnings: engineWarnings,
    settlementStatus: settlementDirection == null
        ? SettlementStatus.settled
        : SettlementStatus.open,
    settlementDirection: settlementDirection,
    remainingToCollectMinor: changeDueMinor < 0 ? changeDueMinor.abs() : 0,
    remainingToReturnMinor: changeDueMinor > 0 && settlementDirection != null
        ? changeDueMinor
        : 0,
    settlementEvents: const <SettlementEvent>[],
    engineNote: engineNote,
  );
}

void main() {
  test('exact payment shows no suggestions', () {
    final List<TransactionActionSuggestion> suggestions =
        buildEgyptianCurrencyActionSuggestions(
          _record(changeDueMinor: 0, changeStatus: 'exact'),
        );

    expect(suggestions, isEmpty);
  });

  test('overpayment shows persisted payout and persisted alternative plan', () {
    final List<TransactionActionSuggestion> suggestions =
        buildEgyptianCurrencyActionSuggestions(
          _record(
            changeDueMinor: 500,
            changeStatus: 'exact',
            changePlanItems: const <int, int>{500: 1},
            alternativePlanItems: const <Map<int, int>>[
              <int, int>{100: 5},
            ],
          ),
        );

    expect(suggestions, hasLength(2));
    expect(suggestions.first.icon, Icons.assignment_return_outlined);
    expect(suggestions.first.body, contains('1 من فئة 5 جنيه'));
    expect(suggestions.last.title, 'بديل للصرف');
    expect(suggestions.last.body, contains('5 من فئة 1 جنيه'));
  });

  test('underpayment shows persisted completion denominations', () {
    final List<TransactionActionSuggestion> suggestions =
        buildEgyptianCurrencyActionSuggestions(
          _record(
            changeDueMinor: -1000,
            changeStatus: 'underpaid',
            completionPlanItems: const <int, int>{500: 2},
          ),
        );

    expect(suggestions, hasLength(1));
    expect(suggestions.single.title, 'خليه يكملها كده');
    expect(suggestions.single.body, contains('2 من فئة 5 جنيه'));
  });

  test('manual override shows only stored note/status', () {
    final List<TransactionActionSuggestion> suggestions =
        buildEgyptianCurrencyActionSuggestions(
          _record(
            changeDueMinor: 1000,
            changeStatus: 'infeasible',
            manualOverride: true,
            engineNote: 'تم تسجيل العملية كتجاوز يدوي.',
            changePlanItems: const <int, int>{500: 2},
            alternativePlanItems: const <Map<int, int>>[
              <int, int>{100: 10},
            ],
          ),
        );

    expect(suggestions, hasLength(1));
    expect(suggestions.single.title, 'تجاوز يدوي');
    expect(suggestions.single.body, 'تم تسجيل العملية كتجاوز يدوي.');
  });
}
