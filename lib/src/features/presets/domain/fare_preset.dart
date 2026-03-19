class FarePreset {
  const FarePreset({
    required this.id,
    required this.label,
    required this.fareMinor,
    required this.ridersCount,
    required this.amountPaidMinor,
  });

  factory FarePreset.fromJson(Map<dynamic, dynamic> json) {
    return FarePreset(
      id: json['id'] as String,
      label: json['label'] as String,
      fareMinor: json['fareMinor'] as int,
      ridersCount: json['ridersCount'] as int,
      amountPaidMinor: json['amountPaidMinor'] as int,
    );
  }

  final String id;
  final String label;
  final int fareMinor;
  final int ridersCount;
  final int amountPaidMinor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'fareMinor': fareMinor,
      'ridersCount': ridersCount,
      'amountPaidMinor': amountPaidMinor,
    };
  }
}
