// GENERATED FILE — do not edit manually.
//
// Run the following commands to replace this file with real configuration:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Until configured, Firebase initialisation will fail gracefully and all
// analytics calls will be silent no-ops.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-w7WLCDIT9vws96BXTQy5RrgdBvVfSek',
    appId: '1:166280631709:android:9963a331d9bbc783ce0b74',
    messagingSenderId: '166280631709',
    projectId: 'ogra-5bdbf',
    storageBucket: 'ogra-5bdbf.firebasestorage.app',
  );

  // ── Replace the values below with output from `flutterfire configure` ───

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA0DFd3dDIIm5FrxGQZMaXWNLaARMKWEg0',
    appId: '1:166280631709:ios:ca28fd593dbfb589ce0b74',
    messagingSenderId: '166280631709',
    projectId: 'ogra-5bdbf',
    storageBucket: 'ogra-5bdbf.firebasestorage.app',
    iosBundleId: 'com.ogra.app',
  );

}