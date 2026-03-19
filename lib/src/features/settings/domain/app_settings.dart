class AppSettings {
  const AppSettings({
    required this.defaultFareMinor,
    required this.pocketModeEnabled,
    required this.largeButtons,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      defaultFareMinor: 1500,
      pocketModeEnabled: true,
      largeButtons: true,
    );
  }

  factory AppSettings.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return AppSettings.initial();
    }

    return AppSettings(
      defaultFareMinor: (json['defaultFareMinor'] as int?) ?? 1500,
      pocketModeEnabled: (json['pocketModeEnabled'] as bool?) ?? true,
      largeButtons: (json['largeButtons'] as bool?) ?? true,
    );
  }

  final int defaultFareMinor;
  final bool pocketModeEnabled;
  final bool largeButtons;

  AppSettings copyWith({
    int? defaultFareMinor,
    bool? pocketModeEnabled,
    bool? largeButtons,
  }) {
    return AppSettings(
      defaultFareMinor: defaultFareMinor ?? this.defaultFareMinor,
      pocketModeEnabled: pocketModeEnabled ?? this.pocketModeEnabled,
      largeButtons: largeButtons ?? this.largeButtons,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'defaultFareMinor': defaultFareMinor,
      'pocketModeEnabled': pocketModeEnabled,
      'largeButtons': largeButtons,
    };
  }
}
