import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_events.dart';

/// Thin wrapper around [FirebaseAnalytics].
///
/// Every public method is **fire-and-forget** — it never awaits, never throws,
/// and never touches the call-site's execution flow.  The app's core
/// functionality is completely unaffected if Firebase is unavailable.
///
/// Pass `null` to get a silent no-op instance (used when Firebase is not
/// initialised — e.g. missing google-services.json in debug builds).
class AnalyticsService {
  AnalyticsService(this._analytics);

  /// Nullable — all [_log] calls are guarded against null.
  final FirebaseAnalytics? _analytics;

  // ── Core transaction funnel ──────────────────────────────────────────────

  void logSheetOpened() {
    _log(AnalyticsEvent.sheetOpened, <String, Object>{
      AnalyticsParam.hourOfDay: DateTime.now().hour,
    });
  }

  void logTransactionCompleted({
    required int ridersCount,
    required int fareMinor,
    required int amountPaidMinor,
    required int changeDueMinor,
    required bool isFeasible,
    required bool pocketModeEnabled,
    required List<int> denominationsMinor,
    required Map<int, int> changePlanItems,
    required String engineMode,
  }) {
    _log(AnalyticsEvent.transactionCompleted, <String, Object>{
      AnalyticsParam.ridersCount: ridersCount,
      AnalyticsParam.fareEgp: _toEgp(fareMinor),
      AnalyticsParam.amountPaidEgp: _toEgp(amountPaidMinor),
      AnalyticsParam.changeDueEgp: _toEgp(changeDueMinor.abs()),
      AnalyticsParam.isFeasible: isFeasible ? 1 : 0,
      AnalyticsParam.pocketModeEnabled: pocketModeEnabled ? 1 : 0,
      AnalyticsParam.denominationsUsed: _formatDenomList(denominationsMinor),
      AnalyticsParam.denominationCount: denominationsMinor.length,
      AnalyticsParam.changePlanSummary: _formatPlanSummary(changePlanItems),
      AnalyticsParam.engineMode: engineMode,
      AnalyticsParam.hourOfDay: DateTime.now().hour,
    });
  }

  void logTransactionCancelled({
    required int ridersCount,
    required bool hadInput,
  }) {
    _log(AnalyticsEvent.transactionCancelled, <String, Object>{
      AnalyticsParam.ridersCount: ridersCount,
      AnalyticsParam.hadInput: hadInput ? 1 : 0,
    });
  }

  // ── Input behaviour ───────────────────────────────────────────────────────

  void logDenominationTapped(int denominationMinor) {
    _log(AnalyticsEvent.denominationTapped, <String, Object>{
      AnalyticsParam.denominationEgp: _toEgp(denominationMinor),
    });
  }

  // ── Change engine outcomes ────────────────────────────────────────────────

  void logChangeInfeasible({
    required int changeDueMinor,
    required int ridersCount,
    required int fareMinor,
  }) {
    _log(AnalyticsEvent.changeInfeasible, <String, Object>{
      AnalyticsParam.changeDueRounded: _toEgp(changeDueMinor),
      AnalyticsParam.ridersCount: ridersCount,
      AnalyticsParam.fareEgp: _toEgp(fareMinor),
    });
  }

  void logInfeasibleOverrideChosen({
    required int changeDueMinor,
    required int overrideAmountMinor,
  }) {
    _log(AnalyticsEvent.infeasibleOverrideChosen, <String, Object>{
      AnalyticsParam.changeDueEgp: _toEgp(changeDueMinor),
      'override_amount_egp': _toEgp(overrideAmountMinor),
    });
  }

  // ── Fare management ───────────────────────────────────────────────────────

  void logFareAdjusted({
    required int oldFareMinor,
    required int newFareMinor,
  }) {
    _log(AnalyticsEvent.fareAdjusted, <String, Object>{
      AnalyticsParam.oldFareEgp: _toEgp(oldFareMinor),
      AnalyticsParam.newFareEgp: _toEgp(newFareMinor),
      AnalyticsParam.deltaEgp: _toEgp(newFareMinor - oldFareMinor),
    });
  }

  // ── Feature adoption ─────────────────────────────────────────────────────

  void logPocketModeToggled({required bool enabled}) {
    _log(AnalyticsEvent.pocketModeToggled, <String, Object>{
      AnalyticsParam.enabled: enabled ? 1 : 0,
    });
  }

  void logPresetApplied({
    required int ridersCount,
    required int fareMinor,
  }) {
    _log(AnalyticsEvent.presetApplied, <String, Object>{
      AnalyticsParam.ridersCount: ridersCount,
      AnalyticsParam.presetFareEgp: _toEgp(fareMinor),
    });
  }

  // ── Open settlements ─────────────────────────────────────────────────────

  void logSettlementResolved({required int amountMinor}) {
    _log(AnalyticsEvent.settlementResolved, <String, Object>{
      AnalyticsParam.settlementAmountEgp: _toEgp(amountMinor),
    });
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  /// Logs an event, completely silently.  Never awaited, never rethrows.
  void _log(String name, [Map<String, Object>? parameters]) {
    if (_analytics == null) return;
    unawaited(
      _analytics
          .logEvent(name: name, parameters: parameters)
          .catchError((_) {}),
    );
  }

  /// Convert minor units (100 = 1 EGP) to a rounded EGP double.
  double _toEgp(int minor) => (minor / 100).roundToDouble();

  /// "100,50,20" — sorted descending, deduped by occurrence order.
  String _formatDenomList(List<int> denomsMinor) {
    final List<int> sorted = List<int>.of(denomsMinor)
      ..sort((int a, int b) => b.compareTo(a));
    return sorted.map((int d) => _toEgp(d).toInt().toString()).join(',');
  }

  /// "1×100+1×50" — compact change plan for Firebase string param.
  String _formatPlanSummary(Map<int, int> plan) {
    if (plan.isEmpty) return 'none';
    final List<int> denoms = plan.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return denoms
        .map((int d) => '${plan[d]}×${_toEgp(d).toInt()}')
        .join('+');
  }
}
