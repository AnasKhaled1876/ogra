import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import 'engine_facade.dart';
import 'models.dart';
import 'scoring.dart';

final denominationSetProvider = Provider<DenominationSet>((Ref ref) {
  return DenominationSet.egpWithHalf();
});

final scoreWeightsProvider = Provider<ScoreWeights>((Ref ref) {
  return ScoreWeights.defaultsEgp();
});

final engineConfigProvider = Provider<EngineConfig>((Ref ref) {
  final bool pocketModeEnabled = ref.watch(
    settingsProvider.select((appSettings) => appSettings.pocketModeEnabled),
  );

  return EngineConfig.mppDefaults().copyWith(
    preserveSmallChange: pocketModeEnabled,
  );
});

final engineProvider = Provider<ChangeDistributionEngine>((Ref ref) {
  final DenominationSet denomSet = ref.watch(denominationSetProvider);
  final ScoreWeights weights = ref.watch(scoreWeightsProvider);
  return ChangeDistributionEngine(denomSet: denomSet, weights: weights);
});
