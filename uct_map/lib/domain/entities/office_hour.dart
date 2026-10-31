/// Horario de atención de un docente (ms.svg - Schedule Service).
class OfficeHour {
  final String id;
  final String teacherRefId;
  final String? structureRefId;
  final int dayOfWeek; // 1 = Lunes ... 7 = Domingo
  final String startTime; // ej. "14:30"
  final String endTime; // ej. "16:00"

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
    return OfficeHour(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      teacherRefId: (json['teacherRefId'] ?? json['TeacherRefId'] ?? '')
          .toString(),
      structureRefId: json['structureRefId'] as String?,
      dayOfWeek: _parseDay(json['dayOfWeek']),
      startTime: (json['startTime'] ?? json['StartTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? json['EndTime'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherRefId': teacherRefId,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
  };
}
