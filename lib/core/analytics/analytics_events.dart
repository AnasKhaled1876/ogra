/// Firebase Analytics event names and parameter keys for 2ogra.
///
/// Naming convention: snake_case, max 40 chars.
/// All monetary values are stored in Egyptian Pounds (EGP) as doubles.
/// Denomination lists are stored as comma-separated EGP strings e.g. "100,50,20".
abstract final class AnalyticsEvent {
  // ── Core transaction funnel ──────────────────────────────────────────────
  /// Bottom sheet opened — funnel entry point.
  static const String sheetOpened = 'sheet_opened';

  /// Collector confirmed a transaction.
  static const String transactionCompleted = 'transaction_completed';

  /// Collector cancelled / dismissed without confirming.
  static const String transactionCancelled = 'transaction_cancelled';

  // ── Input behaviour ───────────────────────────────────────────────────────
  /// A banknote button was tapped to add a denomination to the input.
  static const String denominationTapped = 'denomination_tapped';

  // ── Change engine outcomes ────────────────────────────────────────────────
  /// Engine could not find a feasible change plan (pocket mode on).
  static const String changeInfeasible = 'change_infeasible';

  /// Collector chose the manual override on an infeasible result.
  static const String infeasibleOverrideChosen = 'infeasible_override_chosen';

  // ── Fare management ───────────────────────────────────────────────────────
  /// Fare per rider was changed.
  static const String fareAdjusted = 'fare_adjusted';

  // ── Feature adoption ─────────────────────────────────────────────────────
  /// Pocket (change inventory) mode was toggled.
  static const String pocketModeToggled = 'pocket_mode_toggled';

  /// A preset was applied (riders + fare shortcut).
  static const String presetApplied = 'preset_applied';

  // ── Open settlements ─────────────────────────────────────────────────────
  /// A pending change-return settlement was resolved.
  static const String settlementResolved = 'settlement_resolved';
}

abstract final class AnalyticsParam {
  // -- Shared ----------------------------------------------------------------
  static const String ridersCount = 'riders_count';
  static const String fareEgp = 'fare_egp';
  static const String pocketModeEnabled = 'pocket_mode_enabled';
  static const String hourOfDay = 'hour_of_day';

  // -- transaction_completed -------------------------------------------------
  static const String amountPaidEgp = 'amount_paid_egp';
  static const String changeDueEgp = 'change_due_egp';
  static const String isFeasible = 'is_feasible';
  static const String denominationsUsed = 'denominations_used';
  static const String denominationCount = 'denomination_count';
  static const String changePlanSummary = 'change_plan_summary';
  static const String engineMode = 'engine_mode';

  // -- transaction_cancelled -------------------------------------------------
  static const String hadInput = 'had_input';

  // -- denomination_tapped ---------------------------------------------------
  static const String denominationEgp = 'denomination_egp';

  // -- change_infeasible -----------------------------------------------------
  static const String changeDueRounded = 'change_due_egp';

  // -- fare_adjusted ---------------------------------------------------------
  static const String oldFareEgp = 'old_fare_egp';
  static const String newFareEgp = 'new_fare_egp';
  static const String deltaEgp = 'delta_egp';

  // -- pocket_mode_toggled ---------------------------------------------------
  static const String enabled = 'enabled';

  // -- preset_applied --------------------------------------------------------
  static const String presetFareEgp = 'preset_fare_egp';

  // -- settlement_resolved ---------------------------------------------------
  static const String settlementAmountEgp = 'settlement_amount_egp';
}
