import 'package:hive/hive.dart';

import '../domain/pending_commit.dart';

class PendingCommitRepo {
  PendingCommitRepo(this._box);

  final Box<Map> _box;
  static const String _key = 'current';

  PendingCommit? load() {
    final Map<dynamic, dynamic>? json = _box.get(_key);
    if (json == null) {
      return null;
    }
    return PendingCommit.fromJson(json);
  }

  Future<void> save(PendingCommit commit) {
    return _box.put(_key, commit.toJson());
  }

  Future<void> clear() {
    return _box.delete(_key);
  }
}
