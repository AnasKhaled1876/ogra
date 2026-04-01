import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_sheet_container.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../application/collect_controller.dart';
import '../../application/collect_state.dart';
import '../../domain/transaction_draft.dart';
import '../../domain/transaction_result.dart';
import '../helpers/received_money_formatter.dart';
import '../widgets/infeasible_change_notice.dart';
import '../widgets/transaction_riders_selector.dart';

// Denominations ordered by how often a collector receives them.
// Row 1: large bills (most common payment)
// Row 2: medium bills
// Row 3: small / coins
const List<List<_NoteSpec>> _noteRows = <List<_NoteSpec>>[
  <_NoteSpec>[
    _NoteSpec(minor: 20000, label: '200', color: Color(0xFF1D4ED8)),
    _NoteSpec(minor: 10000, label: '100', color: Color(0xFF7C3AED)),
    _NoteSpec(minor: 5000, label: '50', color: Color(0xFFB45309)),
  ],
  <_NoteSpec>[
    _NoteSpec(minor: 2000, label: '20', color: Color(0xFF166534)),
    _NoteSpec(minor: 1000, label: '10', color: Color(0xFF0F766E)),
    _NoteSpec(minor: 500, label: '5', color: Color(0xFF9A3412)),
  ],
  <_NoteSpec>[
    _NoteSpec(minor: 100, label: '1', color: Color(0xFF374151)),
    _NoteSpec(minor: 50, label: '½', color: Color(0xFF374151)),
  ],
];

class TransactionSheet extends ConsumerWidget {
  const TransactionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CollectState state = ref.watch(collectProvider);
    final TransactionDraft draft = state.draft ?? TransactionDraft.initial();
    final TransactionResult? result = ref.watch(collectResultProvider);
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    final bool hasInput = draft.receivedDenominationsMinor.isNotEmpty;
    final Map<int, int> counts = countDenominations(
      draft.receivedDenominationsMinor,
    );

    return AppSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'عملية جديدة',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              // Backspace replaces the old "delete last" button
              AnimatedOpacity(
                opacity: hasInput ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: IconButton(
                  icon: const Icon(Icons.backspace_outlined, size: 22),
                  color: tokens.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: hasInput ? () => _removeLastNote(ref, draft) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Zone A: Riders ───────────────────────────────────────────────
          TransactionRidersSelector(
            selectedRidersCount: draft.ridersCount,
            onSelected: (int v) =>
                ref.read(collectProvider.notifier).setDraftRidersCount(v),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Zone B: Banknotes ────────────────────────────────────────────
          // Row 1 — large bills (3 equal buttons, taller for easy tap)
          _NoteRow(
            notes: _noteRows[0],
            counts: counts,
            height: 72,
            fontSize: 26,
            onTap: (int minor) => _appendNote(ref, draft, minor),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Row 2 — medium bills
          _NoteRow(
            notes: _noteRows[1],
            counts: counts,
            height: 58,
            fontSize: 20,
            onTap: (int minor) => _appendNote(ref, draft, minor),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Row 3 — small / coins (left-aligned, narrower)
          Row(
            children: <Widget>[
              ..._noteRows[2].map((_NoteSpec note) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                  child: _NoteButton(
                    note: note,
                    count: counts[note.minor] ?? 0,
                    height: 48,
                    width: 72,
                    fontSize: 16,
                    onTap: () => _appendNote(ref, draft, note.minor),
                  ),
                );
              }),
              const Spacer(),
              // Long-press hint for clear
              if (hasInput)
                GestureDetector(
                  onTap: () => _clearNotes(ref),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Text(
                      'مسح الكل',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tokens.textMuted,
                        decoration: TextDecoration.underline,
                        decorationColor: tokens.textMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Zone C: Result ───────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: result != null
                ? _ResultCard(
                    key: const ValueKey<String>('result'),
                    draft: draft,
                    result: result,
                    tokens: tokens,
                  )
                : _EmptyResultHint(
                    key: const ValueKey<String>('hint'),
                    tokens: tokens,
                    hasDenominations: hasInput,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Actions ──────────────────────────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
                  result == null ? null : () => _confirmTransaction(context, ref),
              child: const Text('تأكيد'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: () => _cancel(context, ref, draft),
            child: Text(
              'إلغاء',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  void _appendNote(WidgetRef ref, TransactionDraft draft, int minor) {
    ref.read(collectProvider.notifier).setDraftReceivedDenominationsMinor(
          <int>[...draft.receivedDenominationsMinor, minor],
        );
    ref.read(analyticsProvider).logDenominationTapped(minor);
  }

  void _removeLastNote(WidgetRef ref, TransactionDraft draft) {
    if (draft.receivedDenominationsMinor.isEmpty) return;
    ref.read(collectProvider.notifier).setDraftReceivedDenominationsMinor(
          List<int>.of(draft.receivedDenominationsMinor)..removeLast(),
        );
  }

  void _clearNotes(WidgetRef ref) {
    ref
        .read(collectProvider.notifier)
        .setDraftReceivedDenominationsMinor(const <int>[]);
  }

  Future<void> _confirmTransaction(BuildContext context, WidgetRef ref) async {
    final NavigatorState navigator = Navigator.of(context);
    final bool confirmed =
        await ref.read(collectProvider.notifier).confirmDraftTransaction();
    if (confirmed && navigator.mounted) {
      navigator.pop();
    }
  }

  void _cancel(BuildContext context, WidgetRef ref, TransactionDraft draft) {
    ref.read(analyticsProvider).logTransactionCancelled(
          ridersCount: draft.ridersCount,
          hadInput: draft.receivedDenominationsMinor.isNotEmpty,
        );
    ref.read(collectProvider.notifier).resetDraft();
    Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Note spec
// ─────────────────────────────────────────────────────────────────────────────

class _NoteSpec {
  const _NoteSpec({
    required this.minor,
    required this.label,
    required this.color,
  });

  final int minor;
  final String label;
  final Color color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Note row — 3 equal-width buttons
// ─────────────────────────────────────────────────────────────────────────────

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    required this.notes,
    required this.counts,
    required this.height,
    required this.fontSize,
    required this.onTap,
  });

  final List<_NoteSpec> notes;
  final Map<int, int> counts;
  final double height;
  final double fontSize;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (int i = 0; i < notes.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _NoteButton(
              note: notes[i],
              count: counts[notes[i].minor] ?? 0,
              height: height,
              fontSize: fontSize,
              onTap: () => onTap(notes[i].minor),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Note button — replaces the old image-tile design
// ─────────────────────────────────────────────────────────────────────────────

class _NoteButton extends StatelessWidget {
  const _NoteButton({
    required this.note,
    required this.count,
    required this.height,
    required this.fontSize,
    required this.onTap,
    this.width,
  });

  final _NoteSpec note;
  final int count;
  final double height;
  final double? width;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool active = count > 0;
    final Color bg = active
        ? note.color.withValues(alpha: 0.22)
        : note.color.withValues(alpha: 0.10);
    final Color border = active
        ? note.color.withValues(alpha: 0.7)
        : note.color.withValues(alpha: 0.25);

    return SizedBox(
      height: height,
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Ink(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: border, width: active ? 1.5 : 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Denomination
                Text(
                  note.label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: fontSize,
                    color: active
                        ? Color.lerp(note.color, Colors.white, 0.55)
                        : note.color.withValues(alpha: 0.85),
                  ),
                ),
                // Count badge — top-start corner
                if (active)
                  PositionedDirectional(
                    top: 5,
                    start: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: note.color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'x$count',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result card — compact 3-metric row + change plan
// ─────────────────────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.draft,
    required this.result,
    required this.tokens,
    super.key,
  });

  final TransactionDraft draft;
  final TransactionResult result;
  final OgraUiTokens tokens;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isOwed = result.status == TransactionStatus.amountStillOwed;
    final Color changeColor = isOwed ? tokens.warning : scheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tokens.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 3-metric row
          Row(
            children: <Widget>[
              _Metric(
                label: 'المطلوب',
                value: formatMoneyMinor(result.totalDueMinor),
              ),
              _Metric(
                label: 'المدفوع',
                value: formatMoneyMinor(draft.amountPaidMinor),
              ),
              _Metric(
                label: isOwed ? 'الباقي عليه' : 'الباقي ليه',
                value: formatMoneyMinor(result.changeDueMinor.abs()),
                valueColor: changeColor,
              ),
            ],
          ),

          // Change plan
          if (_planText != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _planText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

          // Infeasible notice
          if (!result.feasible && result.infeasibleReason != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            InfeasibleChangeNotice(
              reason: result.infeasibleReason!,
              statusColors: tokens,
            ),
          ],
        ],
      ),
    );
  }

  String? get _planText {
    if (result.status == TransactionStatus.exact) return 'بدون صرف';
    if (result.bestChangePlanItems.isNotEmpty) {
      return 'الصرف: ${_formatPlan(result.bestChangePlanItems)}';
    }
    if (result.completionPlanItems.isNotEmpty) {
      return 'التكملة: ${_formatPlan(result.completionPlanItems)}';
    }
    return result.note;
  }

  String _formatPlan(Map<int, int> items) {
    final List<int> denoms = items.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return denoms
        .map((int d) => '${items[d]}×${formatDenominationLabel(d)}')
        .join(' + ');
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state hint
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyResultHint extends StatelessWidget {
  const _EmptyResultHint({
    required this.tokens,
    required this.hasDenominations,
    super.key,
  });

  final OgraUiTokens tokens;
  final bool hasDenominations;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Text(
        hasDenominations
            ? 'اختار عدد الركاب لتكتمل الحسبة.'
            : 'اضغط على الفئة اللي الراكب دفعها.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: tokens.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
