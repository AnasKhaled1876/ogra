import 'settlement_models.dart';

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.createdAt,
    required this.fareMinor,
    required this.ridersCount,
    required this.receivedDenominationsMinor,
    required this.amountPaidMinor,
    required this.totalDueMinor,
    required this.changeDueMinor,
    required this.changePlanItems,
    required this.alternativePlanItems,
    required this.completionPlanItems,
    required this.feasible,
    required this.manualOverride,
    required this.engineModeUsed,
    required this.changeStatus,
    required this.engineWarnings,
    required this.settlementStatus,
    required this.settlementDirection,
    required this.remainingToCollectMinor,
    required this.remainingToReturnMinor,
    required this.settlementEvents,
    this.engineNote,
  });

  factory TransactionRecord.fromJson(Map<dynamic, dynamic> json) {
    final List<dynamic>? rawReceived =
        json['receivedDenominationsMinor'] as List<dynamic>?;
    final int amountPaidMinor = json['amountPaidMinor'] as int;
    final bool feasible = json['feasible'] as bool;
    final bool manualOverride = json['manualOverride'] as bool;
    final int changeDueMinor = json['changeDueMinor'] as int;
    final String? rawSettlementStatus = json['settlementStatus'] as String?;
    final String? rawSettlementDirection =
        json['settlementDirection'] as String?;
    final SettlementStatus settlementStatus = _decodeSettlementStatus(
      rawSettlementStatus,
      changeDueMinor: changeDueMinor,
      feasible: feasible,
      manualOverride: manualOverride,
    );
    final int remainingToCollectMinor =
        (json['remainingToCollectMinor'] as int?) ??
        ((rawSettlementStatus == null &&
                rawSettlementDirection == null &&
                changeDueMinor < 0)
            ? changeDueMinor.abs()
            : 0);
    final int remainingToReturnMinor =
        (json['remainingToReturnMinor'] as int?) ??
        ((rawSettlementStatus == null &&
                rawSettlementDirection == null &&
                changeDueMinor > 0 &&
                (!feasible || manualOverride))
            ? changeDueMinor
            : 0);
    final SettlementDirection? settlementDirection = _decodeSettlementDirection(
      rawSettlementDirection,
      settlementStatus: settlementStatus,
      remainingToCollectMinor: remainingToCollectMinor,
      remainingToReturnMinor: remainingToReturnMinor,
      changeDueMinor: changeDueMinor,
      feasible: feasible,
      manualOverride: manualOverride,
    );

    return TransactionRecord(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      fareMinor: json['fareMinor'] as int,
      ridersCount: json['ridersCount'] as int,
      receivedDenominationsMinor: rawReceived == null || rawReceived.isEmpty
          ? <int>[amountPaidMinor]
          : rawReceived.cast<int>(),
      amountPaidMinor: amountPaidMinor,
      totalDueMinor: json['totalDueMinor'] as int,
      changeDueMinor: changeDueMinor,
      changePlanItems: _decodePlan(json['changePlanItems']),
      alternativePlanItems: _decodePlanList(json['alternativePlanItems']),
      completionPlanItems: _decodePlan(json['completionPlanItems']),
      feasible: feasible,
      manualOverride: manualOverride,
      engineModeUsed: (json['engineModeUsed'] as String?) ?? 'fastGreedy',
      changeStatus: (json['changeStatus'] as String?) ?? 'exact',
      engineWarnings:
          ((json['engineWarnings'] as List<dynamic>?) ?? const <dynamic>[])
              .map((dynamic warning) => warning.toString())
              .toList(growable: false),
      settlementStatus: settlementStatus,
      settlementDirection: settlementDirection,
      remainingToCollectMinor: remainingToCollectMinor,
      remainingToReturnMinor: remainingToReturnMinor,
      settlementEvents:
          ((json['settlementEvents'] as List<dynamic>?) ?? const <dynamic>[])
              .map(
                (dynamic rawEvent) =>
                    SettlementEvent.fromJson(rawEvent as Map<dynamic, dynamic>),
              )
              .toList(growable: false),
      engineNote: json['engineNote'] as String?,
    );
  }

  final String id;
  final DateTime createdAt;
  final int fareMinor;
  final int ridersCount;
  final List<int> receivedDenominationsMinor;
  final int amountPaidMinor;
  final int totalDueMinor;
  final int changeDueMinor;
  final Map<int, int> changePlanItems;
  final List<Map<int, int>> alternativePlanItems;
  final Map<int, int> completionPlanItems;
  final bool feasible;
  final bool manualOverride;
  final String engineModeUsed;
  final String changeStatus;
  final List<String> engineWarnings;
  final SettlementStatus settlementStatus;
  final SettlementDirection? settlementDirection;
  final int remainingToCollectMinor;
  final int remainingToReturnMinor;
  final List<SettlementEvent> settlementEvents;
  final String? engineNote;

  bool get isSettled => settlementStatus == SettlementStatus.settled;

  bool get isOpen => !isSettled;

  List<int> get allReceivedDenominationsMinor {
    return <int>[
      ...receivedDenominationsMinor,
      ...settlementEvents.expand(
        (SettlementEvent event) => event.receivedDenominationsMinor,
      ),
    ];
  }

  Map<int, int> get allReturnedDenominationCounts {
    final Map<int, int> counts = Map<int, int>.from(changePlanItems);
    for (final SettlementEvent event in settlementEvents) {
      for (final int denominationMinor in event.returnedDenominationsMinor) {
        counts.update(
          denominationMinor,
          (int value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }
    return counts;
  }

  TransactionRecord copyWith({
    Map<int, int>? changePlanItems,
    List<Map<int, int>>? alternativePlanItems,
    Map<int, int>? completionPlanItems,
    bool? feasible,
    bool? manualOverride,
    String? engineModeUsed,
    String? changeStatus,
    List<String>? engineWarnings,
    SettlementStatus? settlementStatus,
    SettlementDirection? settlementDirection,
    bool clearSettlementDirection = false,
    int? remainingToCollectMinor,
    int? remainingToReturnMinor,
    List<SettlementEvent>? settlementEvents,
    String? engineNote,
    bool clearEngineNote = false,
  }) {
    return TransactionRecord(
      id: id,
      createdAt: createdAt,
      fareMinor: fareMinor,
      ridersCount: ridersCount,
      receivedDenominationsMinor: receivedDenominationsMinor,
      amountPaidMinor: amountPaidMinor,
      totalDueMinor: totalDueMinor,
      changeDueMinor: changeDueMinor,
      changePlanItems: changePlanItems ?? this.changePlanItems,
      alternativePlanItems: alternativePlanItems ?? this.alternativePlanItems,
      completionPlanItems: completionPlanItems ?? this.completionPlanItems,
      feasible: feasible ?? this.feasible,
      manualOverride: manualOverride ?? this.manualOverride,
      engineModeUsed: engineModeUsed ?? this.engineModeUsed,
      changeStatus: changeStatus ?? this.changeStatus,
      engineWarnings: engineWarnings ?? this.engineWarnings,
      settlementStatus: settlementStatus ?? this.settlementStatus,
      settlementDirection: clearSettlementDirection
          ? null
          : (settlementDirection ?? this.settlementDirection),
      remainingToCollectMinor:
          remainingToCollectMinor ?? this.remainingToCollectMinor,
      remainingToReturnMinor:
          remainingToReturnMinor ?? this.remainingToReturnMinor,
      settlementEvents: settlementEvents ?? this.settlementEvents,
      engineNote: clearEngineNote ? null : (engineNote ?? this.engineNote),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'fareMinor': fareMinor,
      'ridersCount': ridersCount,
      'receivedDenominationsMinor': receivedDenominationsMinor,
      'amountPaidMinor': amountPaidMinor,
      'totalDueMinor': totalDueMinor,
      'changeDueMinor': changeDueMinor,
      'changePlanItems': <String, int>{
        for (final MapEntry<int, int> entry in changePlanItems.entries)
          '${entry.key}': entry.value,
      },
      'alternativePlanItems': alternativePlanItems
          .map(_encodePlan)
          .toList(growable: false),
      'completionPlanItems': _encodePlan(completionPlanItems),
      'feasible': feasible,
      'manualOverride': manualOverride,
      'engineModeUsed': engineModeUsed,
      'changeStatus': changeStatus,
      'engineWarnings': engineWarnings,
      'settlementStatus': settlementStatus.name,
      'settlementDirection': settlementDirection?.name,
      'remainingToCollectMinor': remainingToCollectMinor,
      'remainingToReturnMinor': remainingToReturnMinor,
      'settlementEvents': settlementEvents
          .map((SettlementEvent event) => event.toJson())
          .toList(growable: false),
      'engineNote': engineNote,
    };
  }
}

SettlementStatus _decodeSettlementStatus(
  String? rawStatus, {
  required int changeDueMinor,
  required bool feasible,
  required bool manualOverride,
}) {
  if (rawStatus != null) {
    return SettlementStatus.values.byName(rawStatus);
  }

  if (changeDueMinor == 0) {
    return SettlementStatus.settled;
  }

  if (changeDueMinor < 0) {
    return SettlementStatus.open;
  }

  if (changeDueMinor > 0 && feasible && !manualOverride) {
    return SettlementStatus.settled;
  }

  return SettlementStatus.open;
}

SettlementDirection? _decodeSettlementDirection(
  String? rawDirection, {
  required SettlementStatus settlementStatus,
  required int remainingToCollectMinor,
  required int remainingToReturnMinor,
  required int changeDueMinor,
  required bool feasible,
  required bool manualOverride,
}) {
  if (rawDirection != null) {
    return SettlementDirection.values.byName(rawDirection);
  }

  if (settlementStatus == SettlementStatus.settled) {
    return null;
  }

  if (remainingToCollectMinor > 0) {
    return SettlementDirection.collectMore;
  }

  if (remainingToReturnMinor > 0) {
    return SettlementDirection.returnChange;
  }

  if (changeDueMinor < 0) {
    return SettlementDirection.collectMore;
  }

  if (changeDueMinor > 0 && (!feasible || manualOverride)) {
    return SettlementDirection.returnChange;
  }

  return null;
}

Map<int, int> _decodePlan(dynamic rawPlan) {
  final Map<dynamic, dynamic> rawItems =
      (rawPlan as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};

  return <int, int>{
    for (final MapEntry<dynamic, dynamic> entry in rawItems.entries)
      int.parse(entry.key as String): entry.value as int,
  };
}

List<Map<int, int>> _decodePlanList(dynamic rawPlans) {
  return ((rawPlans as List<dynamic>?) ?? const <dynamic>[])
      .map((dynamic rawPlan) => _decodePlan(rawPlan as Map<dynamic, dynamic>?))
      .where((Map<int, int> plan) => plan.isNotEmpty)
      .toList(growable: false);
}

Map<String, int> _encodePlan(Map<int, int> plan) {
  return <String, int>{
    for (final MapEntry<int, int> entry in plan.entries)
      '${entry.key}': entry.value,
  };
}
