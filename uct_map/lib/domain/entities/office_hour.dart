/// Horario de atención de un docente (ms.svg - Schedule Service).
class OfficeHour {
  final String id;
  final String teacherRefId;
  final String? structureRefId;
  final int dayOfWeek; // 1 = Lunes ... 7 = Domingo
  final String startTime; // ej. "14:30"
  final String endTime; // ej. "16:00"

  String get startLabel => _timeLabel(startTime);
  String get endLabel => _timeLabel(endTime);

  bool contains(DateTime start, {int durationMinutes = 30}) {
    if (durationMinutes <= 0 || start.weekday != dayOfWeek) return false;
    final ticks =
        (start.hour * 3600 + start.minute * 60 + start.second) * 10000000 +
        (start.millisecond * 1000 + start.microsecond) * 10;
    return ticks >= _timeTicks(startTime) &&
        ticks + durationMinutes * 60 * 10000000 <= _timeTicks(endTime);
  }

  /// Inicios de consultas completas, a precisión de minutos, dentro del bloque.
  List<DateTime> slotsOn(DateTime date, {int durationMinutes = 30}) {
    if (durationMinutes <= 0 || date.weekday != dayOfWeek) return [];
    const minuteTicks = 60 * 10000000;
    final first = (_timeTicks(startTime) + minuteTicks - 1) ~/ minuteTicks;
    final slots = <DateTime>[];
    for (var minute = first; minute < 24 * 60; minute += durationMinutes) {
      final start = DateTime(
        date.year,
        date.month,
        date.day,
        minute ~/ 60,
        minute % 60,
      );
      if (!contains(start, durationMinutes: durationMinutes)) break;
      slots.add(start);
    }
    return slots;
  }

  static String _timeLabel(String value) =>
      _timeTicks(value) % (60 * 10000000) == 0 ? value.substring(0, 5) : value;

  static int _timeTicks(String value) {
    final match = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d)(?:\.(\d{1,7}))?)?$',
    ).firstMatch(value);
    if (match == null) throw const FormatException('Hora de atención inválida');
    return (int.parse(match[1]!) * 3600 +
                int.parse(match[2]!) * 60 +
                int.parse(match[3] ?? '0')) *
            10000000 +
        int.parse((match[4] ?? '').padRight(7, '0'));
  }

  const OfficeHour({
    required this.id,
    required this.teacherRefId,
    this.structureRefId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Día $dayOfWeek';
    }
  }

  static int _parseDay(dynamic value) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (value is int && value >= 0 && value <= 6) return value == 0 ? 7 : value;
    final index = days.indexOf(value.toString());
    if (index < 0) throw const FormatException('Día de atención inválido');
    return index + 1;
  }

  factory OfficeHour.fromJson(Map<String, dynamic> json) {
    final hour = OfficeHour(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      teacherRefId: (json['teacherRefId'] ?? json['TeacherRefId'] ?? '')
          .toString(),
      structureRefId: json['structureRefId'] as String?,
      dayOfWeek: _parseDay(json['dayOfWeek']),
      startTime: (json['startTime'] ?? json['StartTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? '').toString(),
    );
    if (_timeTicks(hour.endTime) <= _timeTicks(hour.startTime)) {
      throw const FormatException(
        'El fin de atención debe ser posterior al inicio',
      );
    }
    return hour;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherRefId': teacherRefId,
    'structureRefId': structureRefId,
    'dayOfWeek': dayOfWeek % 7,
    'startTime': startTime,
    'endTime': endTime,
  };
}
