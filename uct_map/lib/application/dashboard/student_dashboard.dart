import '../../domain/entities/office_hour.dart';
import '../../domain/repositories/identity_repository.dart';
import '../../domain/repositories/campus_repository.dart';
import '../../domain/entities/schedule_meeting.dart';
import '../../domain/repositories/schedule_repository.dart';

Future<ScheduleMeeting?> loadNextStudentMeeting(
  ScheduleRepository repository,
  String studentId,
) async {
  return _loadNextMeeting(repository, studentId, teacher: false);
}

Future<ScheduleMeeting?> loadNextTeacherMeeting(
  ScheduleRepository repository,
  String teacherId,
) => _loadNextMeeting(repository, teacherId, teacher: true);

Future<ScheduleMeeting?> _loadNextMeeting(
  ScheduleRepository repository,
  String ownerId, {
  required bool teacher,
}) async {
  final meetings = await repository.getMyMeetings();
  return _upcomingMeetings(
    meetings,
    ownerId,
    teacher: teacher,
    now: DateTime.now(),
  ).firstOrNull;
}

List<ScheduleMeeting> _upcomingMeetings(
  List<ScheduleMeeting> meetings,
  String ownerId, {
  required bool teacher,
  required DateTime now,
}) {
  if (meetings.any(
    (meeting) =>
        (teacher ? meeting.teacherRefId : meeting.studentRefId) != ownerId,
  )) {
    throw const FormatException('Las citas no corresponden a tu cuenta.');
  }
  final upcoming =
      meetings.where((m) => m.isActive && !m.scheduledAt.isBefore(now)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return upcoming;
}

class DashboardDay {
  DashboardDay({
    required this.next,
    required this.otherToday,
    required this.hours,
    required this.names,
    required this.locations,
    required this.hoursUnavailable,
    required this.labelsIncomplete,
  });
  final ScheduleMeeting? next;
  final List<ScheduleMeeting> otherToday;
  final List<OfficeHour> hours;
  final Map<String, String> names;
  final Map<String, String> locations;
  final bool hoursUnavailable;
  final bool labelsIncomplete;
}

Future<DashboardDay> loadDashboardDay({
  required ScheduleRepository schedule,
  required IdentityRepository identity,
  required CampusRepository campus,
  required String userId,
  required bool teacher,
  required void Function() checkSession,
  DateTime? now,
}) async {
  checkSession();
  final meetings = await schedule.getMyMeetings();
  checkSession();
  final current = (now ?? DateTime.now()).toLocal();
  final upcoming = _upcomingMeetings(
    meetings,
    userId,
    teacher: teacher,
    now: current,
  );
  final next = upcoming.firstOrNull;
  final todayEnd = DateTime(current.year, current.month, current.day + 1);
  final otherToday = upcoming
      .where(
        (m) => m.id != next?.id && m.scheduledAt.toLocal().isBefore(todayEnd),
      )
      .toList();
  var hours = <OfficeHour>[];
  var hoursUnavailable = false;
  if (teacher) {
    try {
      final ownHours = await schedule.getOfficeHours(userId);
      checkSession();
      if (ownHours.any((h) => h.teacherRefId != userId)) {
        throw const FormatException('La atención no corresponde al docente.');
      }
      hours = ownHours.where((h) => h.dayOfWeek == current.weekday).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (_) {
      checkSession();
      hoursUnavailable = true;
    }
  }
  final visible = [if (next != null) next, ...otherToday];
  final names = <String, String>{};
  final locations = <String, String>{};
  var labelsIncomplete = false;
  if (visible.isNotEmpty) {
    final ids = visible
        .map((m) => teacher ? m.studentRefId : m.teacherRefId)
        .toSet();
    try {
      final users = await identity.getUsers();
      checkSession();
      for (final user in users) {
        if (ids.contains(user.id) && user.name.trim().isNotEmpty)
          names[user.id] = user.name;
      }
      labelsIncomplete = ids.any((id) => !names.containsKey(id));
    } catch (_) {
      checkSession();
      labelsIncomplete = true;
    }
  }
  final places = {
    ...visible.map((m) => m.structureRefId),
    ...hours.map((h) => h.structureRefId),
  }.whereType<String>().where((id) => id.isNotEmpty);
  for (final id in places) {
    checkSession();
    try {
      final place = await campus.getStructureById(id);
      checkSession();
      if (place.id != id || place.name.trim().isEmpty)
        throw const FormatException('Lugar no válido.');
      locations[id] = place.name;
    } catch (_) {
      checkSession();
      labelsIncomplete = true;
    }
  }
  return DashboardDay(
    next: next,
    otherToday: otherToday,
    hours: hours,
    names: names,
    locations: locations,
    hoursUnavailable: hoursUnavailable,
    labelsIncomplete: labelsIncomplete,
  );
}
