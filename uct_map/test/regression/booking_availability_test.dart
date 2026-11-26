import 'fixture_routes.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/data/datasources/schedule_remote_ds.dart';
import 'package:uct_map/domain/entities/booking_interval.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/schedule_time.dart';

import 'session_fixture.dart' show MemoryStorage, account;

void main() {
  test('lunes, domingo y límites generan solo consultas completas', () {
    for (final date in [DateTime(2026, 11, 2), DateTime(2026, 11, 8)]) {
      final hour = OfficeHour(
        id: 'h',
        teacherRefId: 't',
        dayOfWeek: date.weekday,
        startTime: '09:00:30.0000001',
        endTime: '10:31',
      );
      expect(hour.slotsOn(date).map((d) => '${d.hour}:${d.minute}'), [
        '9:1',
        '9:31',
        '10:1',
      ]);
      expect(hour.slotsOn(date).every(hour.contains), isTrue);
      expect(hour.slotsOn(date.add(const Duration(days: 1))), isEmpty);
      expect(hour.slotsOn(date, durationMinutes: 0), isEmpty);
    }
  });

  test('solapamiento parcial y límites contiguos de intervalos', () {
    final busy = BookingInterval(
      start: DateTime(2026, 11, 2, 9, 15),
      end: DateTime(2026, 11, 2, 10),
    );
    expect(busy.overlaps(DateTime(2026, 11, 2, 9)), isTrue);
    expect(busy.overlaps(DateTime(2026, 11, 2, 9, 30)), isTrue);
    expect(busy.overlaps(DateTime(2026, 11, 2, 10)), isFalse);
    expect(busy.overlaps(DateTime(2026, 11, 2, 8, 45)), isFalse);
  });

  test(
    'medianoche y salto de hora respetan el día civil de Santiago',
    () {
      final transition = DateTime(2026, 9, 6);
      expect(parseScheduleInstant('2026-09-06T03:59:00').day, 5);
      expect(parseScheduleInstant('2026-09-06T04:00:00').hour, 1);
      final hour = OfficeHour(
        id: 'office',
        teacherRefId: 'teacher',
        dayOfWeek: DateTime.sunday,
        startTime: '00:00',
        endTime: '02:00',
      );
      expect(hour.slotsOn(transition).map((slot) => slot.minute), [0, 30]);
    },
    skip: DateTime(2026, 9, 6).hour == 0
        ? 'Requiere TZ=America/Santiago.'
        : false,
  );

  Map<String, dynamic> meeting({String status = 'Pending'}) => {
    'teacherRefId': 'teacher',
    'studentRefId': 'other-student',
    'scheduledAt': DateTime(2026, 11, 2, 9, 15).toUtc().toIso8601String(),
    'durationMinutes': 45,
    'status': status,
  };

  Future<SessionController> useSession() async {
    final session = SessionController(storage: MemoryStorage());
    await account(session, 'student', 'Student');
    ApiClientProvider.initialize(session);
    return session;
  }

  test('consulta acotada por docente y día; incluye citas propias sin retener participantes', () async {
    final session = await useSession();
    try {
      final paths = <String>[];
      final source = ScheduleRemoteDataSource(
        client: MockClient((request) async {
          paths.add(request.url.path);
          expect(
            request.url.queryParameters['from'],
            DateTime(2026, 11, 2).toUtc().toIso8601String(),
          );
          expect(
            request.url.queryParameters['to'],
            DateTime(2026, 11, 3).toUtc().toIso8601String(),
          );
          if (request.url.path == ApiEndpoints.scheduleMeetings) {
            expect(request.url.queryParameters['teacherId'], 'teacher');
            return http.Response(
              jsonEncode([
                meeting(),
                meeting(status: 'Cancelled'),
                {
                  ...meeting(status: 'Completed'),
                  'scheduledAt': DateTime(
                    2026,
                    11,
                    2,
                    11,
                    0,
                  ).toUtc().toIso8601String(),
                },
              ]),
              200,
            );
          }
          expect(request.url.path, FixtureRoutes.studentMeetings('student'));
          return http.Response(
            jsonEncode({
              'meetings': [
                {
                  ...meeting(),
                  'studentRefId': 'student',
                  'teacherRefId': 'another',
                  'scheduledAt': DateTime(
                    2026,
                    11,
                    2,
                    10,
                    30,
                  ).toUtc().toIso8601String(),
                },
              ],
            }),
            200,
          );
        }),
      );
      final busy = await source.getBusyIntervals(
        teacherId: 'teacher',
        date: DateTime(2026, 11, 2),
      );
      expect(paths.length, 2);
      expect(busy.length, 3);
      expect(busy.first.start, DateTime(2026, 11, 2, 9, 15));
      expect(busy.first.end, DateTime(2026, 11, 2, 10));
      expect(
        busy.any((b) => b.overlaps(DateTime(2026, 11, 2, 10, 30))),
        isTrue,
      );
    } finally {
      session.dispose();
      ApiClientProvider.reset();
    }
  });

  for (final invalid in [
    <String, dynamic>{'durationMinutes': null},
    {'durationMinutes': -10},
    {'durationMinutes': '30'},
    {'scheduledAt': 'invalid'},
    {'status': 'unknown'},
  ]) {
    test('respuesta inválida no se interpreta como libre: $invalid', () async {
      final session = await useSession();
      try {
        final source = ScheduleRemoteDataSource(
          client: MockClient(
            (request) async => http.Response(
              jsonEncode(
                request.url.path.contains('/students/')
                    ? {'meetings': []}
                    : [
                        {...meeting(), ...invalid},
                      ],
              ),
              200,
            ),
          ),
        );
        await expectLater(
          source.getBusyIntervals(
            teacherId: 'teacher',
            date: DateTime(2026, 11, 2),
          ),
          throwsFormatException,
        );
      } finally {
        session.dispose();
        ApiClientProvider.reset();
      }
    });
  }

  test(
    'cierre de sesión descarta una respuesta de ocupación en vuelo',
    () async {
      final session = await useSession();
      try {
        final gate = Completer<http.Response>();
        final source = ScheduleRemoteDataSource(
          client: MockClient(
            (request) async => request.url.path.contains('/students/')
                ? http.Response('{"meetings":[]}', 200)
                : gate.future,
          ),
        );
        final future = source.getBusyIntervals(
          teacherId: 'teacher',
          date: DateTime(2026, 11, 2),
        );
        final check = expectLater(
          future,
          throwsA(isA<UnauthorizedException>()),
        );
        await session.signOut();
        gate.complete(http.Response('[]', 200));
        await check;
      } finally {
        session.dispose();
        ApiClientProvider.reset();
      }
    },
  );
}
