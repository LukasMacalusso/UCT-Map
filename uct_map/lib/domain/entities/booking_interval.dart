/// Intervalo ocupado sin identidades de participantes ni detalles de una cita.
class BookingInterval {
  const BookingInterval({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool overlaps(DateTime candidate, {int durationMinutes = 30}) =>
      candidate.isBefore(end) &&
      candidate.add(Duration(minutes: durationMinutes)).isAfter(start);
}
