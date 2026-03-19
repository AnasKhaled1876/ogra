import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_radius.dart';
import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_section_card.dart';
import '../../../../core/ui/widgets/app_sheet_container.dart';
import '../../application/collect_controller.dart';
import '../../application/collect_state.dart';
import '../../domain/transaction_draft.dart';
import '../../domain/transaction_result.dart';
import '../helpers/received_money_formatter.dart';
import '../widgets/transaction_preview_card.dart';
import '../widgets/transaction_riders_selector.dart';

class TransactionSheet extends ConsumerStatefulWidget {
  const TransactionSheet({super.key});

  @override
  ConsumerState<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends ConsumerState<TransactionSheet> {
  static const Duration _moneyDebounceDuration = Duration(milliseconds: 300);

  late final TextEditingController _moneyController;
  Timer? _moneyDebounce;
  String? _moneyErrorText;

  @override
  void initState() {
    super.initState();
    final TransactionDraft draft =
        ref.read(collectProvider).draft ?? TransactionDraft.initial();
    _moneyController = TextEditingController(
      text: draft.receivedDenominationsMinor.isEmpty
          ? ''
          : formatDenominationsInputValue(draft.receivedDenominationsMinor),
    );
  }

  @override
  void dispose() {
    _moneyDebounce?.cancel();
    _moneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CollectState state = ref.watch(collectProvider);
    final TransactionDraft draft = state.draft ?? TransactionDraft.initial();
    final TransactionResult? result = ref.watch(collectResultProvider);
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;

    return AppSheetContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'عملية جديدة',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TransactionRidersSelector(
            selectedRidersCount: draft.ridersCount,
            onSelected: (int value) {
              ref.read(collectProvider.notifier).setDraftRidersCount(value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'الفلوس المستلمة',
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
                color: _moneyErrorText == null
                    ? tokens.borderSubtle
                    : tokens.error,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _moneyController,
              keyboardType: TextInputType.text,
              autofocus: draft.receivedDenominationsMinor.isEmpty,
              onChanged: _handleMoneyChanged,
              onEditingComplete: _applyMoneyInputImmediately,
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
                filled: false,
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
            'اكتب الفئات زي 10, 5, 0.5 أو 50.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.textMuted),
          ),
          if (_moneyErrorText != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _moneyErrorText!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: tokens.error),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: result == null
                ? Text(
                    'اختار الفلوس علشان تشوف الحساب.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  )
                : TransactionPreviewCard(
                    draft: draft,
                    result: result,
                    statusColors: tokens,
                  ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: result == null ? null : _confirmTransaction,
              child: Text(
                'تأكيد',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _cancel,
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

  void _cancel() {
    ref.read(collectProvider.notifier).resetDraft();
    Navigator.of(context).pop();
  }

  void _handleMoneyChanged(String value) {
    final String rawValue = value.trim();
    final List<int>? parsedDenominationsMinor = parseDenominationsInput(
      rawValue,
    );

    if (rawValue.isEmpty) {
      _moneyDebounce?.cancel();
      _setMoneyError(null);
      ref
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(const <int>[]);
      return;
    }

    if (parsedDenominationsMinor == null) {
      _moneyDebounce?.cancel();
      _setMoneyError('اكتب فئات صحيحة زي 10, 5, 0.5 أو 50.');
      return;
    }

    _setMoneyError(null);
    _scheduleMoneyPreview(parsedDenominationsMinor);
  }

  Future<void> _confirmTransaction() async {
    _applyMoneyInputImmediately();
    final NavigatorState navigator = Navigator.of(context);
    final bool confirmed = await ref
        .read(collectProvider.notifier)
        .confirmDraftTransaction();
    if (confirmed && navigator.mounted) {
      navigator.pop();
    }
  }

  void _scheduleMoneyPreview(List<int> denominationsMinor) {
    _moneyDebounce?.cancel();
    _moneyDebounce = Timer(_moneyDebounceDuration, () {
      if (!mounted) {
        return;
      }
      ref
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(denominationsMinor);
    });
  }

  void _applyMoneyInputImmediately() {
    _moneyDebounce?.cancel();
    final String rawValue = _moneyController.text.trim();
    if (rawValue.isEmpty) {
      ref
          .read(collectProvider.notifier)
          .setDraftReceivedDenominationsMinor(const <int>[]);
      return;
    }

    final List<int>? parsedDenominationsMinor = parseDenominationsInput(
      rawValue,
    );
    if (parsedDenominationsMinor == null) {
      return;
    }

    ref
        .read(collectProvider.notifier)
        .setDraftReceivedDenominationsMinor(parsedDenominationsMinor);
  }

  void _setMoneyError(String? message) {
    if (_moneyErrorText == message) {
      return;
    }

    setState(() {
      _moneyErrorText = message;
    });
  }
}
