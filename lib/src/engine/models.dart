import 'package:flutter/foundation.dart';

typedef Money = int;
typedef Denom = int;

@immutable
class DenominationSet {
  const DenominationSet({
    required this.denomsDesc,
    required this.unit,
    required this.gcd,
  });

  factory DenominationSet.egpWithHalf() {
    return const DenominationSet(
      denomsDesc: <int>[20000, 10000, 5000, 2000, 1000, 500, 100, 50],
      unit: 50,
      gcd: 50,
    );
  }

  final List<Denom> denomsDesc;
  final Money unit;
  final Money gcd;

  bool contains(Denom denominationMinor) {
    return denomsDesc.contains(denominationMinor);
  }
}

@immutable
class PocketInventory {
  const PocketInventory(this.counts);

  factory PocketInventory.initial() {
    final DenominationSet denomSet = DenominationSet.egpWithHalf();
    return PocketInventory(<Denom, int>{
      for (final int denominationMinor in denomSet.denomsDesc)
        denominationMinor: 0,
    });
  }

  factory PocketInventory.fromJson(Map<dynamic, dynamic>? json) {
    final DenominationSet denomSet = DenominationSet.egpWithHalf();
    final Map<dynamic, dynamic> rawCounts =
        (json?['counts'] as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};

    return PocketInventory(<Denom, int>{
      for (final int denominationMinor in denomSet.denomsDesc)
        denominationMinor: (rawCounts['$denominationMinor'] as int?) ?? 0,
    });
  }

  final Map<Denom, int> counts;

  int countOf(Denom denominationMinor) => counts[denominationMinor] ?? 0;

  PocketInventory copyWith({Map<Denom, int>? counts}) {
    return PocketInventory(counts ?? this.counts);
  }

  PocketInventory addDenom(Denom denominationMinor, int delta) {
    final Map<Denom, int> nextCounts = Map<Denom, int>.from(counts);
    final int nextValue = (nextCounts[denominationMinor] ?? 0) + delta;
    if (nextValue < 0) {
      throw StateError('Pocket underflow for denom=$denominationMinor');
    }
    nextCounts[denominationMinor] = nextValue;
    return PocketInventory(nextCounts);
  }

  PocketInventory addPaymentDenominations(List<Denom> denominationsMinor) {
    PocketInventory next = this;
    for (final int denominationMinor in denominationsMinor) {
      next = next.addDenom(denominationMinor, 1);
    }
    return next;
  }

  PocketInventory applyChange(List<ChangeItem> items) {
    PocketInventory next = this;
    for (final ChangeItem item in items) {
      next = next.addDenom(item.denomMinor, -item.count);
    }
    return next;
  }

  bool canPay(List<ChangeItem> items) {
    for (final ChangeItem item in items) {
      if (countOf(item.denomMinor) < item.count) {
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'counts': <String, int>{
        for (final MapEntry<int, int> entry in counts.entries)
          '${entry.key}': entry.value,
      },
    };
  }
}

@immutable
class PassengerPayment {
  const PassengerPayment({
    required this.id,
    required this.riders,
    required this.paidMinor,
    this.receivedDenominationsMinor = const <Denom>[],
  });

  factory PassengerPayment.fromDenominations({
    required String id,
    required int riders,
    required List<Denom> receivedDenominationsMinor,
  }) {
    return PassengerPayment(
      id: id,
      riders: riders,
      paidMinor: receivedDenominationsMinor.fold<int>(
        0,
        (int sum, int denominationMinor) => sum + denominationMinor,
      ),
      receivedDenominationsMinor: receivedDenominationsMinor,
    );
  }

  final String id;
  final int riders;
  final Money paidMinor;
  final List<Denom> receivedDenominationsMinor;
}

@immutable
class PassengerDue {
  const PassengerDue({
    required this.id,
    required this.riders,
    required this.dueMinor,
    required this.paidMinor,
    required this.changeDueMinor,
  });

  final String id;
  final int riders;
  final Money dueMinor;
  final Money paidMinor;
  final Money changeDueMinor;
}

@immutable
class ChangeItem {
  const ChangeItem(this.denomMinor, this.count);

  final Denom denomMinor;
  final int count;
}

enum ChangeStatus { exact, rounded, infeasible, underpaid }

@immutable
class ChangePlan {
  const ChangePlan({
    required this.passengerId,
    required this.status,
    required this.dueMinor,
    required this.paidMinor,
    required this.changeDueMinor,
    required this.items,
    required this.roundingDeltaMinor,
    this.note,
  });

  static const ChangePlan empty = ChangePlan(
    passengerId: '',
    status: ChangeStatus.exact,
    dueMinor: 0,
    paidMinor: 0,
    changeDueMinor: 0,
    items: <ChangeItem>[],
    roundingDeltaMinor: 0,
  );

  final String passengerId;
  final ChangeStatus status;
  final Money dueMinor;
  final Money paidMinor;
  final Money changeDueMinor;
  final List<ChangeItem> items;
  final Money roundingDeltaMinor;
  final String? note;

  int get totalItems {
    return items.fold<int>(0, (int sum, ChangeItem item) => sum + item.count);
  }
}

enum EngineMode { fastGreedy, smartDp, batchSearch, fallbackGreedy }

@immutable
class BatchAllocationResult {
  const BatchAllocationResult({
    required this.modeUsed,
    required this.plans,
    required this.pocketAfter,
    required this.warnings,
    required this.latencyMs,
  });

  final EngineMode modeUsed;
  final List<ChangePlan> plans;
  final PocketInventory pocketAfter;
  final List<String> warnings;
  final int latencyMs;
}

@immutable
class EngineConfig {
  const EngineConfig({
    required this.preserveSmallChange,
    required this.minimizeNoteCount,
    required this.roundingEnabled,
    required this.roundingMaxMinor,
    required this.roundingOnlyIfInfeasible,
    required this.topKPlansPerPassenger,
    required this.searchDepthLimit,
    required this.timeBudgetMs,
  });

  factory EngineConfig.mppDefaults() => const EngineConfig(
    preserveSmallChange: true,
    minimizeNoteCount: true,
    roundingEnabled: false,
    roundingMaxMinor: 0,
    roundingOnlyIfInfeasible: true,
    topKPlansPerPassenger: 8,
    searchDepthLimit: 10,
    timeBudgetMs: 300,
  );

  final bool preserveSmallChange;
  final bool minimizeNoteCount;
  final bool roundingEnabled;
  final Money roundingMaxMinor;
  final bool roundingOnlyIfInfeasible;
  final int topKPlansPerPassenger;
  final int searchDepthLimit;
  final int timeBudgetMs;

  EngineConfig copyWith({
    bool? preserveSmallChange,
    bool? minimizeNoteCount,
    bool? roundingEnabled,
    Money? roundingMaxMinor,
    bool? roundingOnlyIfInfeasible,
    int? topKPlansPerPassenger,
    int? searchDepthLimit,
    int? timeBudgetMs,
  }) {
    return EngineConfig(
      preserveSmallChange: preserveSmallChange ?? this.preserveSmallChange,
      minimizeNoteCount: minimizeNoteCount ?? this.minimizeNoteCount,
      roundingEnabled: roundingEnabled ?? this.roundingEnabled,
      roundingMaxMinor: roundingMaxMinor ?? this.roundingMaxMinor,
      roundingOnlyIfInfeasible:
          roundingOnlyIfInfeasible ?? this.roundingOnlyIfInfeasible,
      topKPlansPerPassenger:
          topKPlansPerPassenger ?? this.topKPlansPerPassenger,
      searchDepthLimit: searchDepthLimit ?? this.searchDepthLimit,
      timeBudgetMs: timeBudgetMs ?? this.timeBudgetMs,
    );
  }
}
