String formatMoneyMinor(int amountMinor) {
  final int absAmount = amountMinor.abs();
  final int pounds = absAmount ~/ 100;
  final int remainder = absAmount % 100;
  final String sign = amountMinor < 0 ? '-' : '';

  if (remainder == 0) {
    return '$sign$pounds جنيه';
  }

  final String fraction = remainder.toString().padLeft(2, '0');
  return '$sign$pounds.$fraction جنيه';
}

String formatDenominationLabel(int amountMinor) {
  final int pounds = amountMinor ~/ 100;
  final int remainder = amountMinor % 100;
  if (remainder == 0) {
    return '$pounds';
  }

  if (remainder == 50) {
    return '$pounds.5';
  }

  final String fraction = remainder.toString().padLeft(2, '0');
  return '$pounds.$fraction';
}
