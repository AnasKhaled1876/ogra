import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_service.dart';

/// Provides the singleton [AnalyticsService].
///
/// Reads from [FirebaseAnalytics.instance] — safe to call even if Firebase
/// was not successfully initialised (calls will silently no-op via catchError).
final analyticsProvider = Provider<AnalyticsService>((Ref ref) {
  try {
    return AnalyticsService(FirebaseAnalytics.instance);
  } catch (_) {
    // Firebase not initialised — return a silent no-op service.
    return AnalyticsService(null);
  }
});
