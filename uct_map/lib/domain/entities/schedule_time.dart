final _explicitZone = RegExp(r'(?:[zZ]|[+-]\d{2}(?::?\d{2})?)$');

/// Schedule serializes UTC timestamps without a suffix in some responses.
DateTime parseScheduleInstant(Object? value) {
  if (value is! String || !value.contains('T')) {
    throw const FormatException('Fecha de Schedule inválida.');
  }
  return DateTime.parse(_explicitZone.hasMatch(value) ? value : '${value}Z')
      .toLocal();
}
