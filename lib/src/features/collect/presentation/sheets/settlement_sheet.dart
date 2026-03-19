import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_section_card.dart';
import '../../../../core/ui/widgets/app_sheet_container.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../application/collect_controller.dart';
import '../../application/open_settlement_view.dart';
import '../../domain/settlement_models.dart';
import '../../domain/settlement_preview.dart';
import '../helpers/received_money_formatter.dart';

class SettlementSheet extends ConsumerStatefulWidget {
  const SettlementSheet({required this.recordId, super.key});

  final String recordId;

  @override
  ConsumerState<SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends ConsumerState<SettlementSheet> {
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  late final TextEditingController _moneyController;
  Timer? _debounce;
  String _rawInput = '';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _moneyController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _moneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OpenSettlementView? item = _findItem(ref.watch(openSettlementsProvider));
    if (item == null) {
      return const AppSheetContainer(
        child: Text('التسوية دي اتقفلت أو اتمسحت.'),
      );
    }

    final SettlementPreview? preview = ref
        .read(collectProvider.notifier)
        .previewSettlement(
          recordId: widget.recordId,
          receivedNowDenominationsMinor:
              item.record.settlementDirection == SettlementDirection.collectMore
              ? (_parsedInput ?? const <int>[])
              : const <int>[],
          returnedNowDenominationsMinor:
              item.record.settlementDirection == SettlementDirection.returnChange
              ? (_parsedInput ?? const <int>[])
              : const <int>[],
        );
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final bool isCollectMore =
        item.record.settlementDirection == SettlementDirection.collectMore;
    final bool canConfirm = isCollectMore
        ? _parsedInput != null && _parsedInput!.isNotEmpty && (preview?.feasible ?? false)
        : _parsedInput != null && _parsedInput!.isNotEmpty && (preview?.feasible ?? false);

    return AppSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('تسوية مفتوحة', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${item.record.ridersCount} من ${formatReceivedDenominations(item.record.receivedDenominationsMinor)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isCollectMore ? 'المتبقي عليه' : 'المتبقي ليه',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  formatMoneyMinor(
                    isCollectMore
                        ? item.record.remainingToCollectMinor
                        : item.record.remainingToReturnMinor,
                  ),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isCollectMore ? 'الفلوس المستلمة دلوقتي' : 'الفئات اللي هترجعها',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: tokens.inputSurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: _errorText == null ? tokens.borderSubtle : tokens.error,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _moneyController,
              keyboardType: TextInputType.text,
              autofocus: true,
              onChanged: _handleInputChanged,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: '10, 5, 0.5',
                hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.textMuted,
                  fontSize: 24,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isCollectMore
                ? 'اكتب الفلوس اللي استلمتها من الراكب دلوقتي.'
                : 'اكتب الفئات اللي رجعتها فعلاً، أو استخدم الاقتراح.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
          if (_errorText != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorText!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.error),
            ),
          ],
          if (!isCollectMore && item.currentSuggestedPlan.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _autofillSuggestedPlan,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('استخدم الاقتراح'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: preview == null
                ? Text(
                    'ابدأ اكتب الفئات علشان تشوف التسوية.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
                  )
                : _SettlementPreviewBody(
                    item: item,
                    preview: preview,
                  ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canConfirm ? _confirm : null,
              child: const Text('تأكيد التسوية'),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'إلغاء',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<int>? get _parsedInput => _rawInput.trim().isEmpty
      ? const <int>[]
      : parseDenominationsInput(_rawInput.trim());

  OpenSettlementView? _findItem(List<OpenSettlementView> items) {
    for (final OpenSettlementView item in items) {
      if (item.record.id == widget.recordId) {
        return item;
      }
    }
    return null;
  }

  void _handleInputChanged(String value) {
    _rawInput = value;
    final List<int>? parsed = value.trim().isEmpty
        ? const <int>[]
        : parseDenominationsInput(value.trim());
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = parsed == null ? 'اكتب فئات صحيحة زي 10, 5, 0.5 أو 50.' : null;
      });
    });
  }

  void _autofillSuggestedPlan() {
    final OpenSettlementView? item = _findItem(ref.read(openSettlementsProvider));
    if (item == null || item.currentSuggestedPlan.isEmpty) {
      return;
    }

    final String value = formatDenominationsInputValue(
      expandDenominationCounts(item.currentSuggestedPlan),
    );
    _moneyController.text = value;
    _rawInput = value;
    setState(() {
      _errorText = null;
    });
  }

  Future<void> _confirm() async {
    final OpenSettlementView? item = _findItem(ref.read(openSettlementsProvider));
    final List<int>? parsed = _parsedInput;
    if (item == null || parsed == null || parsed.isEmpty) {
      return;
    }

    final bool confirmed = await ref
        .read(collectProvider.notifier)
        .confirmSettlement(
          recordId: widget.recordId,
          receivedNowDenominationsMinor:
              item.record.settlementDirection == SettlementDirection.collectMore
              ? parsed
              : const <int>[],
          returnedNowDenominationsMinor:
              item.record.settlementDirection == SettlementDirection.returnChange
              ? parsed
              : const <int>[],
        );

    if (confirmed && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _SettlementPreviewBody extends StatelessWidget {
  const _SettlementPreviewBody({
    required this.item,
    required this.preview,
  });

  final OpenSettlementView item;
  final SettlementPreview preview;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final bool isCollectMore =
        item.record.settlementDirection == SettlementDirection.collectMore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _Metric(
                label: isCollectMore ? 'اتطبق من الدفع' : 'المرتجع الآن',
                value: formatMoneyMinor(
                  isCollectMore
                      ? preview.appliedReceivedMinor
                      : preview.appliedReturnedMinor,
                ),
              ),
            ),
            Expanded(
              child: _Metric(
                label: 'المتبقي بعد التسوية',
                value: formatMoneyMinor(
                  preview.remainingToCollectMinorAfter > 0
                      ? preview.remainingToCollectMinorAfter
                      : preview.remainingToReturnMinorAfter,
                ),
                highlight:
                    preview.remainingToCollectMinorAfter == 0 &&
                    preview.remainingToReturnMinorAfter == 0,
              ),
            ),
          ],
        ),
        if (preview.currentCompletionPlan.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'التكملة الباقية: ${_formatPlan(preview.currentCompletionPlan)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (preview.currentSuggestedPlan.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'الخطة المقترحة: ${_formatPlan(preview.currentSuggestedPlan)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (preview.currentAlternativePlans.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'بديل: ${_formatPlan(preview.currentAlternativePlans.first)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
          ),
        ],
        if (preview.note != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            preview.note!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
          ),
        ],
        if (preview.invalidReason != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            preview.invalidReason!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: tokens.error),
          ),
        ],
        if (preview.warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          ...preview.warnings.map((String warning) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: Text(
                warning,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
              ),
            );
          }),
        ],
      ],
    );
  }

  String _formatPlan(Map<int, int> items) {
    final List<int> denoms = items.keys.toList()
      ..sort((int a, int b) => b.compareTo(a));
    return denoms
        .map((int denom) {
          return '${items[denom]} من فئة ${formatDenominationLabel(denom)} جنيه';
        })
        .join(' + ');
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: highlight ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
