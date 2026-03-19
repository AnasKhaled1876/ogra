import 'package:hive/hive.dart';

import '../domain/fare_preset.dart';

class LocalPresetRepo {
  LocalPresetRepo(this._box);

  final Box<Map> _box;

  List<FarePreset> load() {
    if (_box.isEmpty) {
      return _defaultPresets;
    }

    return _box.values
        .map((Map<dynamic, dynamic> json) => FarePreset.fromJson(json))
        .toList()
      ..sort((FarePreset a, FarePreset b) => a.id.compareTo(b.id));
  }

  Future<void> saveAll(List<FarePreset> presets) async {
    await _box.clear();
    for (final FarePreset preset in presets) {
      await _box.put(preset.id, preset.toJson());
    }
  }

  static final List<FarePreset> _defaultPresets = <FarePreset>[
    const FarePreset(
      id: 'preset-1',
      label: 'اتنين من 100',
      fareMinor: 1500,
      ridersCount: 2,
      amountPaidMinor: 10000,
    ),
    const FarePreset(
      id: 'preset-2',
      label: 'واحد من 20',
      fareMinor: 1500,
      ridersCount: 1,
      amountPaidMinor: 2000,
    ),
    const FarePreset(
      id: 'preset-3',
      label: 'ثلاثة من 50',
      fareMinor: 1200,
      ridersCount: 3,
      amountPaidMinor: 5000,
    ),
  ];
}
