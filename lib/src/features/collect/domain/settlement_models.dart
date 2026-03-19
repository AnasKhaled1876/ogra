enum SettlementDirection { collectMore, returnChange }

enum SettlementStatus { settled, open, partiallySettled }

enum SettlementResolutionState { waitingOnPassenger, resolvableNow, blocked }

class SettlementEvent {
  const SettlementEvent({
    required this.id,
    required this.createdAt,
    required this.receivedDenominationsMinor,
    required this.returnedDenominationsMinor,
    required this.remainingToCollectMinorAfter,
    required this.remainingToReturnMinorAfter,
    this.note,
  });

  factory SettlementEvent.fromJson(Map<dynamic, dynamic> json) {
    return SettlementEvent(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      receivedDenominationsMinor:
          ((json['receivedDenominationsMinor'] as List<dynamic>?) ??
                  const <dynamic>[])
              .cast<int>(),
      returnedDenominationsMinor:
          ((json['returnedDenominationsMinor'] as List<dynamic>?) ??
                  const <dynamic>[])
              .cast<int>(),
      remainingToCollectMinorAfter:
          (json['remainingToCollectMinorAfter'] as int?) ?? 0,
      remainingToReturnMinorAfter:
          (json['remainingToReturnMinorAfter'] as int?) ?? 0,
      note: json['note'] as String?,
    );
  }

  final String id;
  final DateTime createdAt;
  final List<int> receivedDenominationsMinor;
  final List<int> returnedDenominationsMinor;
  final int remainingToCollectMinorAfter;
  final int remainingToReturnMinorAfter;
  final String? note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'receivedDenominationsMinor': receivedDenominationsMinor,
      'returnedDenominationsMinor': returnedDenominationsMinor,
      'remainingToCollectMinorAfter': remainingToCollectMinorAfter,
      'remainingToReturnMinorAfter': remainingToReturnMinorAfter,
      'note': note,
    };
  }
}
