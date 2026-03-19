import '../../../../core/constants/denominations.dart';
import '../../../../core/utils/money_formatter.dart';

String formatReceivedDenominations(List<int> denominationsMinor) {
  if (denominationsMinor.isEmpty) {
    return '--';
  }

  return denominationsMinor
      .map(
        (int denominationMinor) => formatDenominationLabel(denominationMinor),
      )
      .join(' + ');
}

String normalizeArabicDigits(String input) {
  const Map<String, String> replacements = <String, String>{
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  return input.split('').map((String character) {
    return replacements[character] ?? character;
  }).join();
}

String normalizeMoneyInput(String input) {
  return normalizeArabicDigits(
    input.replaceAll('٫', '.').replaceAll('،', ',').replaceAll('+', ','),
  );
}

List<int>? parseDenominationsInput(String rawValue) {
  if (rawValue.isEmpty) {
    return null;
  }

  final String normalizedValue = normalizeMoneyInput(rawValue);
  final List<String> parts = normalizedValue
      .split(',')
      .map((String value) => value.trim())
      .where((String value) => value.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return null;
  }

  final List<int> denominationsMinor = <int>[];
  for (final String part in parts) {
    final double? denomination = double.tryParse(part);
    if (denomination == null || denomination <= 0) {
      return null;
    }

    final int denominationMinor = (denomination * 100).round();
    if (!kDenominationsMinor.contains(denominationMinor)) {
      return null;
    }

    denominationsMinor.add(denominationMinor);
  }

  return denominationsMinor;
}

String formatDenominationsInputValue(List<int> denominationsMinor) {
  return denominationsMinor
      .map(
        (int denominationMinor) => formatDenominationLabel(denominationMinor),
      )
      .join(', ');
}

Map<int, int> countDenominations(List<int> denominationsMinor) {
  final Map<int, int> counts = <int, int>{};
  for (final int denominationMinor in denominationsMinor) {
    counts.update(denominationMinor, (int value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}

List<int> expandDenominationCounts(Map<int, int> items) {
  final List<int> expanded = <int>[];
  final List<int> denoms = items.keys.toList()..sort((int a, int b) => b.compareTo(a));
  for (final int denominationMinor in denoms) {
    for (int index = 0; index < (items[denominationMinor] ?? 0); index++) {
      expanded.add(denominationMinor);
    }
  }
  return expanded;
}
