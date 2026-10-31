import '../entities/office_hour.dart';
import '../entities/professor.dart';
import '../entities/schedule_meeting.dart';

/// Contrato del repositorio para consumir el Schedule Service vía API Gateway.
abstract class ScheduleRepository {
  Future<List<Professor>> getProfessors();
  Future<List<OfficeHour>> getOfficeHours(String teacherId);
  Future<List<ScheduleMeeting>> getMyMeetings();
  Future<ScheduleMeeting> createMeeting({
    required String teacherRefId,
    required String structureRefId,
    required DateTime scheduledAt,
    String? studentRefId,
    int durationMinutes = 30,
  });
  Future<bool> updateMeetingStatus(String meetingId, MeetingStatus status);
}
