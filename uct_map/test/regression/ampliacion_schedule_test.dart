import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/data/datasources/schedule_remote_ds.dart';
import 'package:uct_map/domain/entities/schedule_meeting.dart';
import 'package:uct_map/domain/entities/lost_object.dart';

import 'session_fixture.dart' as roles;

Map<String, dynamic> meeting(
  String teacher,
  String student, [
  String status = 'Pending',
]) => {
  'id': 'meeting',
  'teacherRefId': teacher,
  'studentRefId': student,
  'structureRefId': null,
  'scheduledAt': '2030-01-01T09:00:00',
  'durationMinutes': 30,
  'status': status,
};
http.Response json(Object body) => http.Response(jsonEncode(body), 200);

void main() {
  tearDown(ApiClientProvider.reset);
  test('agenda envía rango solicitado y rechaza agenda ajena', () async {
    final session = await roles.signIn('Student');
    addTearDown(session.dispose);
    var own = true;
    final from = DateTime(2030);
    final to = DateTime(2030, 2);
    final client = MockClient((request) async {
      expect(
        request.url.queryParameters['from'],
        from.toUtc().toIso8601String(),
      );
      expect(request.url.queryParameters['to'], to.toUtc().toIso8601String());
      return json({
        'studentRefId': own ? 'user' : 'other',
        'meetings': [meeting('teacher', 'user')],
      });
    });
    ApiClientProvider.initialize(session, innerClient: client);
    final source = ScheduleRemoteDataSource();
    expect(await source.getMyMeetings(from: from, to: to), hasLength(1));
    own = false;
    await expectLater(
      source.getMyMeetings(from: from, to: to),
      throwsA(isA<ForbiddenException>()),
    );
    await expectLater(
      source.getMyMeetings(from: to, to: from),
      throwsArgumentError,
    );
  });
  test(
    'workload requiere Teacher y valida dueño antes de publicar resumen',
    () async {
      final session = await roles.signIn('Teacher');
      addTearDown(session.dispose);
      var own = true;
      final from = DateTime(2030);
      final to = DateTime(2030, 2);
      final client = MockClient(
        (request) async => json({
          'teacherRefId': own ? 'user' : 'other',
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
          'weeklyOfficeHourMinutes': 900,
          'meetingCount': 1,
          'officeHours': [],
          'meetings': [meeting('user', 'student')],
        }),
      );
      ApiClientProvider.initialize(session, innerClient: client);
      final source = ScheduleRemoteDataSource();
      expect(
        (await source.getMyWorkload(
          from: from,
          to: to,
        )).weeklyOfficeHourMinutes,
        900,
      );
      own = false;
      await expectLater(
        source.getMyWorkload(from: from, to: to),
        throwsA(isA<ForbiddenException>()),
      );
    },
  );
  test('Student solo cancela su cita y PATCH usa contrato real', () async {
    final session = await roles.signIn('Student');
    addTearDown(session.dispose);
    var patches = 0;
    ApiClientProvider.initialize(
      session,
      innerClient: MockClient((request) async {
        if (request.method == 'PATCH') {
          patches++;
          expect(request.url.path, ApiEndpoints.meetingStatus('meeting'));
          expect(jsonDecode(request.body), {'status': 'cancelled'});
          return json(meeting('teacher', 'user', 'Cancelled'));
        }
        return json(meeting('teacher', 'user'));
      }),
    );
    final source = ScheduleRemoteDataSource();
    await expectLater(
      source.updateMeetingStatus('meeting', MeetingStatus.confirmed),
      throwsA(isA<ForbiddenException>()),
    );
    expect(patches, 0);
    expect(
      await source.updateMeetingStatus('meeting', MeetingStatus.cancelled),
      isTrue,
    );
    expect(patches, 1);
  });
  test('respuestas tardías no publican cambio tras logout', () async {
    final session = await roles.signIn('Teacher');
    addTearDown(session.dispose);
    ApiClientProvider.initialize(
      session,
      innerClient: MockClient((request) async {
        if (request.method == 'PATCH') {
          await session.signOut();
          return json(meeting('user', 'student', 'Confirmed'));
        }
        return json(meeting('user', 'student'));
      }),
    );
    await expectLater(
      ScheduleRemoteDataSource().updateMeetingStatus(
        'meeting',
        MeetingStatus.confirmed,
      ),
      throwsA(isA<UnauthorizedException>()),
    );
  });
  test('mapea identificador de Incident actualizado sin fabricar uno', () {
    expect(
      LostObject.fromJson({'lostObjectId': 'real-id', 'status': 'Pending'}).id,
      'real-id',
    );
    expect(LostObject.fromJson({'status': 'Pending'}).id, isEmpty);
  });
}
