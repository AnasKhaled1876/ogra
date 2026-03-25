class TransactionDraft {
  const TransactionDraft({
    required this.ridersCount,
    required this.receivedDenominationsMinor,
  });

  factory TransactionDraft.initial() {
    return const TransactionDraft(
      ridersCount: 1,
      receivedDenominationsMinor: <int>[],
    );
  }

  final int ridersCount;
  final List<int> receivedDenominationsMinor;

  int get amountPaidMinor {
    return receivedDenominationsMinor.fold<int>(
      0,
      (int sum, int denominationMinor) => sum + denominationMinor,
    );
  }

  TransactionDraft copyWith({
    int? ridersCount,
    List<int>? receivedDenominationsMinor,
  }) {
    return TransactionDraft(
      ridersCount: ridersCount ?? this.ridersCount,
      receivedDenominationsMinor:
          receivedDenominationsMinor ?? this.receivedDenominationsMinor,
    );
  }
}
