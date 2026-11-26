import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/dashboard/student_dashboard.dart';
import 'package:uct_map/domain/entities/schedule_meeting.dart';
import 'package:uct_map/domain/repositories/schedule_repository.dart';

class _Schedule implements ScheduleRepository {
  _Schedule(this.meetings);
  final List<ScheduleMeeting> meetings;
  @override
  Future<List<ScheduleMeeting>> getMyMeetings({
    DateTime? from,
    DateTime? to,
  }) async => meetings;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ScheduleMeeting meeting(
  String id,
  int hours, {
  String student = 'student',
  MeetingStatus status = MeetingStatus.confirmed,
}) => ScheduleMeeting(
  id: id,
  teacherRefId: 'teacher',
  studentRefId: student,
  structureRefId: null,
  scheduledAt: DateTime.now().add(Duration(hours: hours)),
  status: status,
);
void main() {
  test('dashboard Teacher valida propietario y reutiliza selección de próxima cita', () async {
    final repository = _Schedule([meeting('next', 1)]);
    expect((await loadNextTeacherMeeting(repository, 'teacher'))!.id, 'next');
    await expectLater(
      loadNextTeacherMeeting(repository, 'other'),
      throwsFormatException,
    );
  });
  test(
    'elige próxima activa, sin ordenar ni modificar la lista del repositorio',
    () async {
      final data = [
        meeting('later', 5),
        meeting('cancelled', 1, status: MeetingStatus.cancelled),
        meeting('past', -1),
        meeting('next', 2),
      ];
      expect(
        (await loadNextStudentMeeting(_Schedule(data), 'student'))!.id,
        'next',
      );
      expect(data.first.id, 'later');
    },
  );
  test('rechaza citas ajenas incluso cuando no son la próxima', () async {
    await expectLater(
      loadNextStudentMeeting(
        _Schedule([meeting('own', 1), meeting('other', 2, student: 'other')]),
        'student',
      ),
      throwsFormatException,
    );
  });
  test('sin citas próximas devuelve vacío sin inventar una clase', () async {
    expect(
      await loadNextStudentMeeting(_Schedule([meeting('past', -2)]), 'student'),
      isNull,
    );
  });
}
