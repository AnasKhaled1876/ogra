import 'package:hive/hive.dart';

import '../domain/app_settings.dart';

class LocalSettingsRepo {
  LocalSettingsRepo(this._box);

  final Box<Map> _box;
  static const String _key = 'current';

  AppSettings load() {
    return AppSettings.fromJson(_box.get(_key));
  }

  Future<void> save(AppSettings settings) {
    return _box.put(_key, settings.toJson());
  }
}
