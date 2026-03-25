import 'package:hive/hive.dart';

import '../domain/pocket_inventory.dart';

class LocalPocketRepo {
  LocalPocketRepo(this._box);

  final Box<Map> _box;
  static const String _key = 'current';

  PocketInventory load() {
    return PocketInventory.fromJson(_box.get(_key));
  }

  Future<void> save(PocketInventory inventory) {
    return _box.put(_key, inventory.toJson());
  }
}
