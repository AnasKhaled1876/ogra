import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/app_spacing.dart';
import '../../../../core/ui/app_theme.dart';
import '../../../../core/ui/widgets/app_sheet_container.dart';
import '../../../settings/application/settings_controller.dart';
import '../../application/collect_controller.dart';

class FareEditSheet extends ConsumerStatefulWidget {
  const FareEditSheet({required this.currentFareMinor, super.key});

  final int currentFareMinor;

  @override
  ConsumerState<FareEditSheet> createState() => _FareEditSheetState();
}

class _FareEditSheetState extends ConsumerState<FareEditSheet> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentFareMinor / 100).toStringAsFixed(
        widget.currentFareMinor % 100 == 0 ? 0 : 2,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final OgraUiTokens tokens = Theme.of(context).extension<OgraUiTokens>()!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return AppSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'تعديل الأجرة',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveFare(),
              autofocus: true,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: scheme.primary,
                fontSize: 58,
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: '15',
                errorText: _errorText,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: tokens.textMuted,
                  fontSize: 58,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'جنيه مصري',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveFare,
              child: const Text('حفظ'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'إلغاء',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  int? _parseFareMinor(String rawValue) {
    if (rawValue.isEmpty) {
      return null;
    }

    final double? value = double.tryParse(rawValue);
    if (value == null || value <= 0) {
      return null;
    }

    return (value * 100).round();
  }

  Future<void> _saveFare() async {
    final int? parsedFareMinor = _parseFareMinor(_controller.text.trim());
    if (parsedFareMinor == null) {
      setState(() {
        _errorText = 'اكتب رقم صحيح للأجرة.';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    ref.read(collectProvider.notifier).setFareMinor(parsedFareMinor);
    await ref.read(settingsProvider.notifier).setDefaultFareMinor(parsedFareMinor);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
