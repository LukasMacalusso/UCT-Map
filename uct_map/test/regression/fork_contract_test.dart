import 'fixture_routes.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/data/datasources/schedule_remote_ds.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/app_permission.dart';
import 'package:uct_map/domain/entities/user_role.dart';

void main() {
  test('días textuales, domingo y estructura del contrato real', () {
    final hour = OfficeHour.fromJson({
      'id': 'h',
      'teacherRefId': 't',
      'structureRefId': 's',
      'dayOfWeek': 'Sunday',
      'startTime': '09:00:00',
      'endTime': '12:00:00',
    });
    expect(hour.dayOfWeek, 7);
    expect(hour.structureRefId, 's');
    expect(
      () => OfficeHour.fromJson({'dayOfWeek': 'NotMonday'}),
      throwsFormatException,
    );
  });
  test('permisos exclusivos de cada apartado', () {
    for (final role in UserRole.values) {
      expect(
        AppPermission.teacherSchedule.allows(role),
        role == UserRole.profesor,
      );
      expect(
        AppPermission.manageUsers.allows(role),
        role == UserRole.administrador,
      );
      expect(
        AppPermission.manageObjects.allows(role),
        role == UserRole.funcionarioObjetos,
      );
      expect(
        AppPermission.manageReports.allows(role),
        role == UserRole.funcionarioQuejas,
      );
    }
  });
  test(
    'directorio selecciona Teacher de Identity y carga su horario real',
    () async {
      final paths = <String>[];
      final repository = ScheduleRemoteDataSource(
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path == FixtureRoutes.identity)
            return http.Response(
              jsonEncode([
                {
                  'userId': 'teacher',
                  'name': 'Docente',
                  'email': 'docente@uct.cl',
                  'role': 'Teacher',
                },
                {
                  'userId': 'student',
                  'name': 'Alumno',
                  'email': 'alumno@uct.cl',
                  'role': 'Student',
                },
              ]),
              200,
            );
          expect(request.url.path, FixtureRoutes.officeHours);
          expect(request.url.queryParameters['teacherId'], 'teacher');
          return http.Response(
            jsonEncode([
              {
                'id': 'h',
                'teacherRefId': 'teacher',
                'dayOfWeek': 'Monday',
                'startTime': '09:00:00',
                'endTime': '12:00:00',
                'structureRefId': 'structure',
              },
            ]),
            200,
          );
        }),
      );
      final result = await repository.getProfessors();
      expect(result.single.id, 'teacher');
      expect(result.single.officeHours.single.dayOfWeek, 1);
      expect(paths, [FixtureRoutes.identity, FixtureRoutes.officeHours]);
    },
  );
  test('reserva envía estudiante, duración y estructura nullable', () async {
    final repository = ScheduleRemoteDataSource(
      client: MockClient((request) async {
        final body = jsonDecode(request.body);
        expect(request.url.path, ApiEndpoints.scheduleMeetings);
        expect(body['studentRefId'], 'student');
        expect(body['durationMinutes'], 30);
        expect(body['structureRefId'], isNull);
        return http.Response(
          jsonEncode({'id': 'm', ...body, 'status': 'Pending'}),
          201,
        );
      }),
    );
    final meeting = await repository.createMeeting(
      teacherRefId: 'teacher',
      studentRefId: 'student',
      structureRefId: '',
      scheduledAt: DateTime(2026, 11, 2, 10),
    );
    expect(meeting.studentRefId, 'student');
  });
  test(
    'fallos de red no producen profesores ficticios ni citas vacías',
    () async {
      final repository = ScheduleRemoteDataSource(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      await expectLater(repository.getProfessors(), throwsException);
      await expectLater(repository.getOfficeHours('teacher'), throwsException);
    },
  );
}
