import '../../domain/entities/schedule_meeting.dart';
import '../../domain/repositories/schedule_repository.dart';

Future<ScheduleMeeting?> loadNextStudentMeeting(
  ScheduleRepository repository,
  String studentId,
) async {
  final meetings = await repository.getMyMeetings();
  if (meetings.any((meeting) => meeting.studentRefId != studentId)) {
    throw const FormatException('Las citas no corresponden a tu cuenta.');
  }
  final now = DateTime.now();
  final upcoming =
      meetings.where((m) => m.isActive && !m.scheduledAt.isBefore(now)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return upcoming.firstOrNull;
}
