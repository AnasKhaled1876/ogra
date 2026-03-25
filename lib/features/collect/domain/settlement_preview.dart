import 'settlement_models.dart';

class SettlementPreview {
  const SettlementPreview({
    required this.recordId,
    required this.direction,
    required this.receivedNowDenominationsMinor,
    required this.returnedNowDenominationsMinor,
    required this.appliedReceivedMinor,
    required this.appliedReturnedMinor,
    required this.remainingToCollectMinorAfter,
    required this.remainingToReturnMinorAfter,
    required this.statusAfter,
    required this.feasible,
    this.currentSuggestedPlan = const <int, int>{},
    this.currentAlternativePlans = const <Map<int, int>>[],
    this.currentCompletionPlan = const <int, int>{},
    this.warnings = const <String>[],
    this.note,
    this.invalidReason,
  });

  final String recordId;
  final SettlementDirection direction;
  final List<int> receivedNowDenominationsMinor;
  final List<int> returnedNowDenominationsMinor;
  final int appliedReceivedMinor;
  final int appliedReturnedMinor;
  final int remainingToCollectMinorAfter;
  final int remainingToReturnMinorAfter;
  final SettlementStatus statusAfter;
  final bool feasible;
  final Map<int, int> currentSuggestedPlan;
  final List<Map<int, int>> currentAlternativePlans;
  final Map<int, int> currentCompletionPlan;
  final List<String> warnings;
  final String? note;
  final String? invalidReason;

  bool get isClosed => statusAfter == SettlementStatus.settled;
}
