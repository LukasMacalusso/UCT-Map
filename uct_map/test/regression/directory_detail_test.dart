import 'test_fonts.dart' show loadUiFonts;
import 'fixture_routes.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/datasources/schedule_remote_ds.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/professor.dart';
import 'package:uct_map/presentation/screens/professors/professor_detail_screen.dart';
import 'package:uct_map/presentation/screens/professors/professors_screen.dart';

import 'session_fixture.dart' show MemoryStorage, account;

void main() {
  setUpAll(() async {
    await loadUiFonts();
  });
  Future<SessionController> signIn(String role) async {
    final session = SessionController(storage: MemoryStorage());
    await account(session, 'viewer', role);
    ApiClientProvider.initialize(session);
    return session;
  }

  const professor = Professor(
    id: 'teacher',
    name: 'Profesora María de los Ángeles González',
    department: '',
    office: '',
    email: 'docente@uct.cl',
    officeHours: [
      OfficeHour(
        id: 'm',
        teacherRefId: 'teacher',
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '12:00',
        structureRefId: 'place',
      ),
      OfficeHour(
        id: 'w',
        teacherRefId: 'teacher',
        dayOfWeek: 3,
        startTime: '10:00',
        endTime: '12:00',
        structureRefId: 'place',
      ),
      OfficeHour(
        id: 'f',
        teacherRefId: 'teacher',
        dayOfWeek: 5,
        startTime: '14:00',
        endTime: '16:00',
        structureRefId: 'place',
      ),
    ],
  );

  testWidgets(
    'lista compacta abre ficha y conserva el texto de búsqueda al volver',
    (tester) async {
      final session = await signIn('Student');
      final source = ScheduleRemoteDataSource(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode(
              request.url.path == FixtureRoutes.identity
                  ? [
                      {
                        'userId': 'teacher',
                        'name': 'Docente Grace',
                        'email': 'grace@uct.cl',
                        'role': 'Teacher',
                      },
                    ]
                  : [
                      {
                        'id': 'h',
                        'teacherRefId': 'teacher',
                        'dayOfWeek': 'Monday',
                        'startTime': '09:00',
                        'endTime': '12:00',
                      },
                    ],
            ),
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: ProfessorsScreen(scheduleRepository: source)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Grace');
      await tester.pump();
      expect(find.text('Lunes'), findsNothing);
      expect(find.text('Agendar Cita'), findsNothing);
      await tester.tap(find.text('Docente Grace'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfessorDetailScreen), findsOneWidget);
      expect(find.text('Lunes'), findsOneWidget);
      expect(find.text('Agendar Cita'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Grace'), findsOneWidget);
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      ApiClientProvider.reset();
    },
  );

  for (final role in [
    'Teacher',
    'Admin',
    'ObjectsOfficer',
    'ComplaintsOfficer',
  ]) {
    testWidgets('ficha no ofrece reserva al rol $role', (tester) async {
      final session = await signIn(role);
      await tester.pumpWidget(
        MaterialApp(
          home: ProfessorDetailScreen(
            professor: professor,
            repository: ScheduleRemoteDataSource(),
            locations: const {'place': 'Sala de consulta'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Agendar Cita'), findsNothing);
      expect(find.text('Horario de atención'), findsOneWidget);
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      ApiClientProvider.reset();
    });
  }

  for (final (size, scale) in [
    (const Size(412, 915), 1.0),
    (const Size(1280, 900), 1.0),
    (const Size(412, 915), 2.0),
  ]) {
    testWidgets('ficha adaptable $size con texto $scale', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = await signIn('Student');
      debugDisableShadows = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF003865),
              primary: const Color(0xFF003865),
              secondary: const Color(0xFFEAA221),
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('detail-capture'),
            child: ProfessorDetailScreen(
              professor: professor,
              repository: ScheduleRemoteDataSource(),
              locations: const {'place': 'Sala de consulta'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      ApiClientProvider.reset();
    });
  }
}
