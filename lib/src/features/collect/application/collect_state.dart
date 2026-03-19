import '../domain/transaction_draft.dart';
import 'open_settlement_view.dart';

class CollectState {
  const CollectState({
    required this.fareMinor,
    this.draft,
    this.snackMessage,
    this.newlyResolvableSettlements = const <OpenSettlementView>[],
  });

  final int fareMinor;
  final TransactionDraft? draft;
  final String? snackMessage;
  final List<OpenSettlementView> newlyResolvableSettlements;

  CollectState copyWith({
    int? fareMinor,
    TransactionDraft? draft,
    String? snackMessage,
    List<OpenSettlementView>? newlyResolvableSettlements,
    bool clearDraft = false,
    bool clearSnackMessage = false,
    bool clearNewlyResolvableSettlements = false,
  }) {
    return CollectState(
      fareMinor: fareMinor ?? this.fareMinor,
      draft: clearDraft ? null : (draft ?? this.draft),
      snackMessage: clearSnackMessage
          ? null
          : (snackMessage ?? this.snackMessage),
      newlyResolvableSettlements: clearNewlyResolvableSettlements
          ? const <OpenSettlementView>[]
          : (newlyResolvableSettlements ?? this.newlyResolvableSettlements),
    );
  }
}
