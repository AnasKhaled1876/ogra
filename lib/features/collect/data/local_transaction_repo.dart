import 'package:hive/hive.dart';

import '../domain/transaction_record.dart';

class LocalTransactionRepo {
  LocalTransactionRepo(this._box);

  final Box<Map> _box;

  List<TransactionRecord> load() {
    return _box.values
        .map((Map<dynamic, dynamic> json) => TransactionRecord.fromJson(json))
        .toList()
      ..sort((TransactionRecord a, TransactionRecord b) {
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<void> save(TransactionRecord record) {
    return _box.put(record.id, record.toJson());
  }

  Future<void> saveAll(List<TransactionRecord> records) {
    return Future.wait<void>(
      records.map((TransactionRecord record) => save(record)),
    );
  }

  Future<void> delete(String id) {
    return _box.delete(id);
  }

  Future<void> clear() {
    return _box.clear();
  }
}
