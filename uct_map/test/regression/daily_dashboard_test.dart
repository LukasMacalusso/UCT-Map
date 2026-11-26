import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/dashboard/student_dashboard.dart';
import 'package:uct_map/domain/entities/dashboard_academic_content.dart';
import 'package:uct_map/domain/entities/schedule_meeting.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/managed_user.dart';
import 'package:uct_map/domain/entities/structure.dart';
import 'package:uct_map/domain/repositories/schedule_repository.dart';
import 'package:uct_map/domain/repositories/identity_repository.dart';
import 'package:uct_map/domain/repositories/campus_repository.dart';
import 'package:uct_map/presentation/screens/home/dashboard_academic_sections.dart';

final now = DateTime(2030, 5, 20, 9);
ScheduleMeeting meeting(
  String id,
  int hours, {
  String student = 'student',
  MeetingStatus status = MeetingStatus.confirmed,
}) => ScheduleMeeting(
  id: id,
  teacherRefId: 'teacher',
  studentRefId: student,
  structureRefId: 'place',
  scheduledAt: now.add(Duration(hours: hours)),
  status: status,
);

class Schedule implements ScheduleRepository {
  Schedule(this.meetings, {this.hours = const [], this.failHours = false});
  final List<ScheduleMeeting> meetings;
  final List<OfficeHour> hours;
  final bool failHours;
  @override
  Future<List<ScheduleMeeting>> getMyMeetings({
    DateTime? from,
    DateTime? to,
  }) async => meetings;
  @override
  Future<List<OfficeHour>> getOfficeHours(String id) async {
    if (failHours) throw StateError('offline');
    return hours;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Identity implements IdentityRepository {
  @override
  Future<List<ManagedUser>> getUsers() async => const [
    ManagedUser(
      id: 'teacher',
      name: 'Docente real de prueba',
      email: 'teacher@example.test',
      role: 'Teacher',
      isSuspended: false,
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Campus implements CampusRepository {
  @override
  Future<Structure> getStructureById(String id) async => Structure(
    id: id,
    campusId: 'campus',
    categoryId: 'category',
    name: 'Sala real de prueba',
    latitude: 0,
    longitude: 0,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<DashboardDay> load(
  Schedule schedule, {
  bool teacher = false,
  void Function()? check,
}) => loadDashboardDay(
  schedule: schedule,
  identity: Identity(),
  campus: Campus(),
  userId: teacher ? 'teacher' : 'student',
  teacher: teacher,
  checkSession: check ?? () {},
  now: now,
);
void main() {
  test('resumen propio ordenado, sin duplicar próxima ni incluir otro día/canceladas', () async {
    final source = [
      meeting('tomorrow', 26),
      meeting('second', 3),
      meeting('next', 1),
      meeting('cancelled', 2, status: MeetingStatus.cancelled),
      meeting('past', -1),
    ];
    final day = await load(Schedule(source));
    expect(day.next!.id, 'next');
    expect(day.otherToday.map((m) => m.id), ['second']);
    expect(source.first.id, 'tomorrow');
    expect(day.names['teacher'], 'Docente real de prueba');
    expect(day.locations['place'], 'Sala real de prueba');
  });
  test(
    'cita ajena se rechaza aunque esté cancelada o fuera del resumen',
    () async {
      await expectLater(
        load(Schedule([meeting('foreign', -1, student: 'other')])),
        throwsFormatException,
      );
    },
  );
  test('Teacher usa solo atención propia del día y ordena bloques', () async {
    final hours = [
      OfficeHour(
        id: 'later',
        teacherRefId: 'teacher',
        dayOfWeek: now.weekday,
        startTime: '14:00',
        endTime: '15:00',
        structureRefId: 'place',
      ),
      OfficeHour(
        id: 'earlier',
        teacherRefId: 'teacher',
        dayOfWeek: now.weekday,
        startTime: '10:00',
        endTime: '11:00',
      ),
      OfficeHour(
        id: 'other-day',
        teacherRefId: 'teacher',
        dayOfWeek: now.weekday % 7 + 1,
        startTime: '10:00',
        endTime: '11:00',
      ),
    ];
    final day = await load(Schedule([], hours: hours), teacher: true);
    expect(day.hours.map((h) => h.id), ['earlier', 'later']);
    expect(day.hoursUnavailable, isFalse);
  });
  test(
    'fallo o propietario ajeno de atención no finge vacío ni expone datos',
    () async {
      for (final source in [
        Schedule([meeting('next', 1)], failHours: true),
        Schedule(
          [meeting('next', 1)],
          hours: [
            OfficeHour(
              id: 'foreign',
              teacherRefId: 'other',
              dayOfWeek: now.weekday,
              startTime: '10:00',
              endTime: '11:00',
            ),
          ],
        ),
      ]) {
        final day = await load(source, teacher: true);
        expect(day.hoursUnavailable, isTrue);
        expect(day.hours, isEmpty);
        expect(day.next!.id, 'next');
      }
    },
  );
  test('cambio de sesión durante carga cancela el resumen', () async {
    var checks = 0;
    await expectLater(
      load(
        Schedule([meeting('next', 1)]),
        check: () {
          if (++checks >= 2) throw StateError('session changed');
        },
      ),
      throwsStateError,
    );
  });
  testWidgets(
    'fuentes académicas no conectadas ocultas, vacías explícitas y propietario protegido',
    (tester) async {
      Future<void> show(
        DashboardAcademicContent? data, {
        String user = 'student',
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DashboardAcademicSections(content: data, userId: user),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(null);
      expect(find.text('Clases de hoy'), findsNothing);
      expect(find.text('Avisos del campus'), findsNothing);
      await show(
        const DashboardAcademicContent(
          userId: 'student',
          classes: [],
          notices: [],
        ),
      );
      expect(find.text('No tienes clases para hoy.'), findsOneWidget);
      expect(find.text('No hay avisos disponibles.'), findsOneWidget);
      final today = DateTime.now();
      final data = DashboardAcademicContent(
        userId: 'student',
        classes: [
          DashboardClass(
            title: 'Clase recibida',
            location: 'Sala recibida',
            startsAt: DateTime(today.year, today.month, today.day, 10),
            endsAt: DateTime(today.year, today.month, today.day, 11),
          ),
        ],
        notices: [
          DashboardNotice(
            title: 'Aviso recibido',
            message: 'Contenido recibido de la fuente',
          ),
        ],
      );
      await show(data);
      expect(find.text('Clase recibida'), findsOneWidget);
      expect(find.text('Aviso recibido'), findsOneWidget);
      await show(data, user: 'other');
      expect(find.text('Clase recibida'), findsNothing);
      expect(find.text('Aviso recibido'), findsNothing);
    },
  );
  test('contenido académico inválido no llega a presentación', () {
    expect(
      () => DashboardNotice(title: '', message: 'text'),
      throwsArgumentError,
    );
    expect(
      () => DashboardClass(
        title: 'Clase',
        location: 'Sala',
        startsAt: now,
        endsAt: now,
      ),
      throwsArgumentError,
    );
  });
}
