import 'office_hour.dart';
import 'schedule_meeting.dart';

class TeacherWorkload {
  const TeacherWorkload({
    required this.teacherRefId,
    required this.from,
    required this.to,
    required this.weeklyOfficeHourMinutes,
    required this.meetingCount,
    required this.officeHours,
    required this.meetings,
  });

  final String teacherRefId;
  final DateTime from;
  final DateTime to;
  final int weeklyOfficeHourMinutes;
  final int meetingCount;
  final List<OfficeHour> officeHours;
  final List<ScheduleMeeting> meetings;
  int get reservedMeetingMinutes => meetings
      .where((meeting) => meeting.status != MeetingStatus.cancelled)
      .fold<int>(0, (total, meeting) => total + meeting.durationMinutes);

  factory TeacherWorkload.fromJson(Map<String, dynamic> json) {
    final from = DateTime.parse(json['from'] as String);
    final to = DateTime.parse(json['to'] as String);
    final minutes = json['weeklyOfficeHourMinutes'] as int;
    final count = json['meetingCount'] as int;
    final meetings = (json['meetings'] as List)
        .map((m) => ScheduleMeeting.fromJson(m as Map<String, dynamic>))
        .toList();
    if (!to.isAfter(from) || minutes < 0 || count != meetings.length) {
      throw const FormatException('Resumen docente inválido.');
    }
    return TeacherWorkload(
      teacherRefId: json['teacherRefId'] as String,
      from: from,
      to: to,
      weeklyOfficeHourMinutes: minutes,
      meetingCount: count,
      officeHours: (json['officeHours'] as List)
          .map((h) => OfficeHour.fromJson(h as Map<String, dynamic>))
          .toList(),
      meetings: meetings,
    );
  }
}
