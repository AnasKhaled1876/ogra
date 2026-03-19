import 'models.dart';

class ScoreWeights {
  const ScoreWeights({
    required this.perNote,
    required this.perDenomUse,
    required this.perDenomDeplete,
  });

  factory ScoreWeights.defaultsEgp() => const ScoreWeights(
    perNote: 10,
    perDenomUse: <Denom, int>{50: 24, 100: 20, 500: 8, 1000: 3},
    perDenomDeplete: <Denom, int>{50: 18, 100: 15, 500: 8, 1000: 4, 2000: 2},
  );

  final int perNote;
  final Map<Denom, int> perDenomUse;
  final Map<Denom, int> perDenomDeplete;
}

int scorePlan({
  required List<ChangeItem> items,
  required PocketInventory pocketBeforePayout,
  required ScoreWeights w,
}) {
  int score = 0;
  int totalNotes = 0;

  for (final ChangeItem item in items) {
    totalNotes += item.count;
    score += (w.perDenomUse[item.denomMinor] ?? 0) * item.count;
  }
  score += totalNotes * w.perNote;

  for (final ChangeItem item in items) {
    final int before = pocketBeforePayout.countOf(item.denomMinor);
    final int after = before - item.count;
    if (after == 0) {
      score += w.perDenomDeplete[item.denomMinor] ?? 0;
    }
  }

  return score;
}
