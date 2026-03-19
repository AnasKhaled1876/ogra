class DailyAggregate {
  const DailyAggregate({
    required this.day,
    required this.transactionCount,
    required this.collectedMinor,
    required this.changeGivenMinor,
    required this.infeasibleCount,
  });

  final DateTime day;
  final int transactionCount;
  final int collectedMinor;
  final int changeGivenMinor;
  final int infeasibleCount;
}
