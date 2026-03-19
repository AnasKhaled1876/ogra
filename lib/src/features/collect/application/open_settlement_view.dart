import '../domain/settlement_models.dart';
import '../domain/transaction_record.dart';

class OpenSettlementView {
  const OpenSettlementView({
    required this.record,
    required this.resolutionState,
    required this.currentSuggestedPlan,
    required this.currentAlternativePlans,
    required this.currentWarnings,
  });

  final TransactionRecord record;
  final SettlementResolutionState resolutionState;
  final Map<int, int> currentSuggestedPlan;
  final List<Map<int, int>> currentAlternativePlans;
  final List<String> currentWarnings;
}
