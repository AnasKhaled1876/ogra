import '../../../engine/models.dart' show PocketInventory;
import 'transaction_record.dart';

class PendingCommit {
  const PendingCommit({
    required this.id,
    required this.records,
    required this.pocketModeEnabled,
    this.pocketAfter,
  });

  factory PendingCommit.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      throw ArgumentError.notNull('json');
    }

    final List<dynamic> rawRecords =
        (json['records'] as List<dynamic>?) ?? <dynamic>[];

    return PendingCommit(
      id: json['id'] as String,
      records: rawRecords
          .map((dynamic rawRecord) {
            return TransactionRecord.fromJson(rawRecord as Map<dynamic, dynamic>);
          })
          .toList(growable: false),
      pocketModeEnabled: (json['pocketModeEnabled'] as bool?) ?? false,
      pocketAfter: json['pocketAfter'] == null
          ? null
          : PocketInventory.fromJson(
              json['pocketAfter'] as Map<dynamic, dynamic>?,
            ),
    );
  }

  final String id;
  final List<TransactionRecord> records;
  final bool pocketModeEnabled;
  final PocketInventory? pocketAfter;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'records': records
          .map((TransactionRecord record) => record.toJson())
          .toList(growable: false),
      'pocketModeEnabled': pocketModeEnabled,
      'pocketAfter': pocketAfter?.toJson(),
    };
  }
}
