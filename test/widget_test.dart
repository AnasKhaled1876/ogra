import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ogra/core/ui/app_theme.dart';
import 'package:ogra/features/collect/presentation/collect_screen.dart';

String? _hiveTestPath;

Future<void> _initHive() async {
  _hiveTestPath ??= Directory.systemTemp.createTempSync('ogra_test_hive_').path;
  Hive.init(_hiveTestPath!);
  if (!Hive.isBoxOpen('app_settings')) {
    await Hive.openBox<Map>('app_settings');
  }
  if (!Hive.isBoxOpen('pocket_state')) {
    await Hive.openBox<Map>('pocket_state');
  }
  if (!Hive.isBoxOpen('transactions')) {
    await Hive.openBox<Map>('transactions');
  }
  if (!Hive.isBoxOpen('pending_commit')) {
    await Hive.openBox<Map>('pending_commit');
  }
  if (!Hive.isBoxOpen('presets')) {
    await Hive.openBox<Map>('presets');
  }
}

Widget _testApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildAppTheme(),
      home: child,
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
}

void main() {
  setUpAll(() async {
    await _initHive();
  });

  setUp(() async {
    await Hive.box<Map>('transactions').clear();
    await Hive.box<Map>('pocket_state').clear();
    await Hive.box<Map>('app_settings').clear();
    await Hive.box<Map>('pending_commit').clear();
  });

  testWidgets('collect screen shows fare context and pocket entry point', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(const CollectScreen()));
    await tester.pumpAndSettle();

    // Primary action button (bottom bar — no FAB in current design)
    expect(find.widgetWithText(ElevatedButton, 'عملية جديدة'), findsOneWidget);
    expect(find.byTooltip('الفكة'), findsOneWidget);
    expect(find.text('عمليات الرحلة'), findsOneWidget);
  });

  testWidgets('pocket sheet opens from the collect header', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_testApp(const CollectScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('الفكة'));
    await tester.pumpAndSettle();

    expect(find.text('الفكة'), findsOneWidget);
    expect(find.text('بداية وردية'), findsOneWidget);
    expect(find.text('تفعيل Pocket Mode'), findsOneWidget);
  });

  testWidgets(
    'transaction sheet shows exact payment preview and enables confirm',
    (WidgetTester tester) async {
      await tester.pumpWidget(_testApp(const CollectScreen()));
      await tester.pumpAndSettle();

      // Open the transaction sheet via the bottom action bar button
      await tester.tap(find.widgetWithText(ElevatedButton, 'عملية جديدة'));
      await tester.pumpAndSettle();

      // Select 2 riders — default fare is 15 EGP, so total due = 30 EGP
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Tap denomination buttons: 20 EGP + 10 EGP = 30 EGP (exact)
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();

      // Result card: المطلوب and المدفوع both show 30 جنيه
      expect(find.textContaining('30 جنيه'), findsWidgets);
      // No change needed — exact payment
      expect(find.text('بدون صرف'), findsOneWidget);

      // Confirm button must be enabled
      final Finder confirmButton = find.widgetWithText(ElevatedButton, 'تأكيد');
      await tester.ensureVisible(confirmButton);
      final ElevatedButton button = tester.widget<ElevatedButton>(confirmButton);
      expect(button.onPressed, isNotNull);
    },
  );
}
