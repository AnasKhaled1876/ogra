import 'package:hive_flutter/hive_flutter.dart';

export 'app.dart';

Future<void> bootstrap() async {
  await Hive.initFlutter();
  await Future.wait(<Future<void>>[
    Hive.openBox<Map>('app_settings'),
    Hive.openBox<Map>('pocket_state'),
    Hive.openBox<Map>('transactions'),
    Hive.openBox<Map>('pending_commit'),
    Hive.openBox<Map>('presets'),
  ]);
}
