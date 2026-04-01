import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../firebase_options.dart';

export 'app.dart';

Future<void> bootstrap() async {
  await Future.wait<void>(<Future<void>>[
    _initFirebase(),
    _initHive(),
  ]);
}

/// Initialises Firebase silently.  If the project is not yet configured
/// (placeholder firebase_options.dart) or any error occurs, the app continues
/// normally and all analytics calls become silent no-ops.
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
    // Route Flutter framework errors to Crashlytics.
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    // Route uncaught async errors (PlatformDispatcher) to Crashlytics.
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {
    // Firebase unavailable — Crashlytics silently inactive.
  }
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  await Future.wait(<Future<void>>[
    Hive.openBox<Map>('app_settings'),
    Hive.openBox<Map>('pocket_state'),
    Hive.openBox<Map>('transactions'),
    Hive.openBox<Map>('pending_commit'),
    Hive.openBox<Map>('presets'),
  ]);
}
