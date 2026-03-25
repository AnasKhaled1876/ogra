import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/local_preset_repo.dart';
import '../domain/fare_preset.dart';

final presetRepoProvider = Provider<LocalPresetRepo>((Ref ref) {
  return LocalPresetRepo(Hive.box<Map>('presets'));
});

final presetsProvider = NotifierProvider<PresetsController, List<FarePreset>>(
  PresetsController.new,
);

class PresetsController extends Notifier<List<FarePreset>> {
  late final LocalPresetRepo _repo;

  @override
  List<FarePreset> build() {
    _repo = ref.read(presetRepoProvider);
    return _repo.load();
  }

  Future<void> savePreset(FarePreset preset) async {
    final List<FarePreset> next = <FarePreset>[
      ...state.where((FarePreset item) => item.id != preset.id),
      preset,
    ]..sort((FarePreset a, FarePreset b) => a.id.compareTo(b.id));

    state = next;
    await _repo.saveAll(next);
  }
}
