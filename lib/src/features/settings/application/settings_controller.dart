import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/local_settings_repo.dart';
import '../domain/app_settings.dart';

final settingsRepoProvider = Provider<LocalSettingsRepo>((Ref ref) {
  return LocalSettingsRepo(Hive.box<Map>('app_settings'));
});

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  late final LocalSettingsRepo _repo;

  @override
  AppSettings build() {
    _repo = ref.read(settingsRepoProvider);
    return _repo.load();
  }

  Future<void> setDefaultFareMinor(int value) async {
    state = state.copyWith(defaultFareMinor: value.clamp(100, 20000));
    await _repo.save(state);
  }

  Future<void> setPocketModeEnabled(bool value) async {
    state = state.copyWith(pocketModeEnabled: value);
    await _repo.save(state);
  }

  Future<void> setLargeButtons(bool value) async {
    state = state.copyWith(largeButtons: value);
    await _repo.save(state);
  }
}
