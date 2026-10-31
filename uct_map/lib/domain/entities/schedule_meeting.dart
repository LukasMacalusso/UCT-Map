/// Estado de una cita o reunión agendada con un docente.
enum MeetingStatus { pending, confirmed, cancelled, completed }

extension MeetingStatusExt on MeetingStatus {
  String get label {
    switch (this) {
      case MeetingStatus.pending:
        return 'Pendiente';
      case MeetingStatus.confirmed:
        return 'Confirmada';
      case MeetingStatus.cancelled:
        return 'Cancelada';
      case MeetingStatus.completed:
        return 'Completada';
    }
  }

  static MeetingStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'confirmed':
      case 'confirmada':
        return MeetingStatus.confirmed;
      case 'cancelled':
      case 'cancelada':
        return MeetingStatus.cancelled;
      case 'completed':
      case 'completada':
        return MeetingStatus.completed;
      case 'pending':
      case 'pendiente':
        return MeetingStatus.pending;
      default:
        throw const FormatException('Estado de cita desconocido');
    }
  }
}

/// Cita agendada entre alumno y docente (ms.svg - Schedule Service).
class ScheduleMeeting {
  final String id;
  final String teacherRefId;
  final String studentRefId;
  final String structureRefId;
  final DateTime scheduledAt;
  final MeetingStatus status;
  final String? teacherName;
  final String? structureName;

  bool get isActive =>
      status == MeetingStatus.pending || status == MeetingStatus.confirmed;

  const ScheduleMeeting({
    required this.id,
    required this.teacherRefId,
    required this.studentRefId,
    required this.structureRefId,
    required this.scheduledAt,
    required this.status,
    this.teacherName,
    this.structureName,
  });

  factory ScheduleMeeting.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['scheduledAt'] ?? json['ScheduledAt'];
    final parsedDate = dateRaw is String ? DateTime.tryParse(dateRaw) : null;
    if (parsedDate == null) {
      throw const FormatException('Fecha de cita inválida');
    }

    final statusRaw = json['status'] ?? json['Status'];
    return ScheduleMeeting(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      teacherRefId: (json['teacherRefId'] ?? json['TeacherRefId'] ?? '')
          .toString(),
      studentRefId: (json['studentRefId'] ?? json['StudentRefId'] ?? '')
          .toString(),
      structureRefId: (json['structureRefId'] ?? json['StructureRefId'] ?? '')
          .toString(),
      scheduledAt: parsedDate,
      status: MeetingStatusExt.fromString(statusRaw?.toString()),
      teacherName:
          json['teacherName']?.toString() ?? json['TeacherName']?.toString(),
      structureName:
          json['structureName']?.toString() ??
          json['StructureName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'teacherRefId': teacherRefId,
    'studentRefId': studentRefId,
    'structureRefId': structureRefId,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status.name,
  };
}
