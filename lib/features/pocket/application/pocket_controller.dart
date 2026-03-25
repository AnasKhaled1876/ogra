import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../data/local_pocket_repo.dart';
import '../domain/pocket_inventory.dart';

final pocketRepoProvider = Provider<LocalPocketRepo>((Ref ref) {
  return LocalPocketRepo(Hive.box<Map>('pocket_state'));
});

final pocketProvider = NotifierProvider<PocketController, PocketInventory>(
  PocketController.new,
);

class PocketController extends Notifier<PocketInventory> {
  late final LocalPocketRepo _repo;

  @override
  PocketInventory build() {
    _repo = ref.read(pocketRepoProvider);
    return _repo.load();
  }

  Future<void> setCount(int denominationMinor, int count) async {
    final Map<int, int> nextCounts = Map<int, int>.from(state.counts)
      ..[denominationMinor] = count.clamp(0, 999);
    state = state.copyWith(counts: nextCounts);
    await _repo.save(state);
  }

  Future<void> changeCount(int denominationMinor, int delta) async {
    final int current = state.counts[denominationMinor] ?? 0;
    await setCount(denominationMinor, current + delta);
  }

  Future<void> replaceInventory(PocketInventory inventory) async {
    state = inventory;
    await _repo.save(state);
  }

  Future<void> applyTransaction({
    required List<int> receivedDenominationsMinor,
    required Map<int, int> changeToGive,
  }) async {
    final Map<int, int> nextCounts = Map<int, int>.from(state.counts);

    for (final int denominationMinor in receivedDenominationsMinor) {
      nextCounts.update(
        denominationMinor,
        (int value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    for (final MapEntry<int, int> entry in changeToGive.entries) {
      nextCounts.update(
        entry.key,
        (int value) => (value - entry.value).clamp(0, 999),
        ifAbsent: () => 0,
      );
    }

    state = state.copyWith(counts: nextCounts);
    await _repo.save(state);
  }

  Future<void> revertTransaction({
    required List<int> receivedDenominationsMinor,
    required Map<int, int> changeToRestore,
  }) async {
    final Map<int, int> nextCounts = Map<int, int>.from(state.counts);

    for (final int denominationMinor in receivedDenominationsMinor) {
      final int currentPaidCount = nextCounts[denominationMinor] ?? 0;
      nextCounts[denominationMinor] = (currentPaidCount - 1).clamp(0, 999);
    }

    for (final MapEntry<int, int> entry in changeToRestore.entries) {
      nextCounts.update(
        entry.key,
        (int value) => (value + entry.value).clamp(0, 999),
        ifAbsent: () => entry.value.clamp(0, 999),
      );
    }

    state = state.copyWith(counts: nextCounts);
    await _repo.save(state);
  }

  Future<void> seedMostlySmallChange() async {
    state = state.copyWith(
      counts: <int, int>{
        20000: 0,
        10000: 1,
        5000: 2,
        2000: 3,
        1000: 6,
        500: 8,
        100: 10,
        50: 8,
      },
    );
    await _repo.save(state);
  }
}
