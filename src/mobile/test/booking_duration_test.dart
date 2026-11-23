import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/domain/entities/booking_interval.dart';
import 'package:uct_map/domain/entities/office_hour.dart';

void main() {
  test('duraciones solo generan intervalos completos dentro del bloque', () {
    const hour = OfficeHour(
      id: '1',
      teacherRefId: 't',
      dayOfWeek: 1,
      startTime: '09:00',
      endTime: '10:00',
    );
    final monday = DateTime(2026, 11, 2);
    expect(hour.slotsOn(monday, durationMinutes: 15).length, 4);
    expect(hour.slotsOn(monday, durationMinutes: 30).length, 2);
    expect(hour.slotsOn(monday, durationMinutes: 45).length, 1);
    expect(hour.slotsOn(monday, durationMinutes: 60).length, 1);
    expect(
      hour.contains(DateTime(2026, 11, 2, 9, 30), durationMinutes: 45),
      isFalse,
    );
  });

  test('la duración seleccionada determina si hay solapamiento', () {
    final busy = BookingInterval(
      start: DateTime(2026, 11, 2, 9, 30),
      end: DateTime(2026, 11, 2, 10),
    );
    final start = DateTime(2026, 11, 2, 9);
    expect(busy.overlaps(start, durationMinutes: 30), isFalse);
    expect(busy.overlaps(start, durationMinutes: 45), isTrue);
  });
}
