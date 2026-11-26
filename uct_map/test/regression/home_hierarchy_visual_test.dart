import 'test_fonts.dart' show loadUiFonts;
import 'fixture_routes.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/schedule_meeting.dart';
import 'package:uct_map/domain/repositories/schedule_repository.dart';
import 'package:uct_map/presentation/screens/home/teacher_home_screen.dart';

import 'session_fixture.dart' as roles;

class _Schedule implements ScheduleRepository {
  _Schedule(this.status);
  final MeetingStatus status;
  @override
  Future<List<ScheduleMeeting>> getMyMeetings({
    DateTime? from,
    DateTime? to,
  }) async => [
    for (final minutes in [10, 60])
      ScheduleMeeting(
        id: 'meeting-$minutes',
        teacherRefId: 'user',
        studentRefId: 'student',
        structureRefId: 'office',
        scheduledAt: DateTime.now().add(Duration(minutes: minutes)),
        status: status,
      ),
  ];
  @override
  Future<List<OfficeHour>> getOfficeHours(String id) async => [
    OfficeHour(
      id: 'hours',
      teacherRefId: id,
      structureRefId: 'office',
      dayOfWeek: DateTime.now().weekday,
      startTime: '09:00',
      endTime: '17:00',
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await loadUiFonts();
  });
  for (final (status, scale) in [
    (MeetingStatus.pending, 1.0),
    (MeetingStatus.pending, 2.0),
    (MeetingStatus.confirmed, 1.0),
  ]) {
    testWidgets(
      'Inicio docente ${status.name} a 390 px, texto $scale sin desbordamientos',
      (tester) async {
        debugDisableShadows = false;
        await tester.binding.setSurfaceSize(const Size(390, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = await roles.signIn('Teacher');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient(
            (request) async => http.Response(
              jsonEncode(
                request.url.path == FixtureRoutes.identity
                    ? [
                        {
                          'userId': 'student',
                          'name': 'María Soto',
                          'email': 'student@example.test',
                          'role': 'Student',
                        },
                      ]
                    : {
                        'id': 'office',
                        'name': 'Sala de consultas · Edificio Central',
                        'campusId': 'campus',
                        'categoryId': 'category',
                      },
              ),
              200,
            ),
          ),
        );
        const key = ValueKey('hierarchy-capture');
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF003865),
                primary: const Color(0xFF003865),
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: TeacherHomeScreen(repository: _Schedule(status)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Próxima consulta'), findsOneWidget);
        expect(find.byIcon(Icons.event_available), findsOneWidget);
        expect(find.text('30 minutos'), findsNothing);
        expect(find.text(status.label), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(status.label)).dy,
          lessThan(tester.getTopLeft(find.text('María Soto').first).dy),
        );
        expect(find.text('Otras consultas de hoy'), findsOneWidget);
        expect(find.text('Atención de hoy'), findsOneWidget);
        expect(tester.takeException(), isNull);
        debugDisableShadows = true;
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
  }
}
