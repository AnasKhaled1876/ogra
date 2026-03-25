enum TransactionStatus { exact, changeDue, amountStillOwed }

class TransactionResult {
  const TransactionResult({
    required this.totalDueMinor,
    required this.changeDueMinor,
    required this.status,
    required this.engineStatus,
    required this.bestChangePlanItems,
    required this.explanation,
    required this.modeUsed,
    this.feasible = true,
    this.alternativePlanItems = const <Map<int, int>>[],
    this.completionPlanItems = const <int, int>{},
    this.warnings = const <String>[],
    this.infeasibleReason,
    this.note,
  });

  final int totalDueMinor;
  final int changeDueMinor;
  final TransactionStatus status;
  final String engineStatus;
  final Map<int, int> bestChangePlanItems;
  final String explanation;
  final String modeUsed;
  final bool feasible;
  final List<Map<int, int>> alternativePlanItems;
  final Map<int, int> completionPlanItems;
  final List<String> warnings;
  final String? infeasibleReason;
  final String? note;
}
