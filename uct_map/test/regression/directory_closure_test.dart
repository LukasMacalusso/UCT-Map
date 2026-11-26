import 'fixture_routes.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/datasources/schedule_remote_ds.dart';
import 'package:uct_map/presentation/screens/professors/professors_screen.dart';

import 'session_fixture.dart' show MemoryStorage, account;

void main() {
  late SessionController session;
  var identityFails = false;
  var scheduleFails = false;
  var campusFails = false;
  final calls = <String>[];
  http.Response response(Object value, [int status = 200]) =>
      http.Response(jsonEncode(value), status);
  const teacher = {
    'userId': 'teacher',
    'name': 'Docente Grace',
    'email': 'grace@uct.cl',
    'role': 'Teacher',
  };
  Future<http.Response> handle(http.Request request) async {
    calls.add(request.url.path);
    switch (request.url.path) {
      case final path when path == FixtureRoutes.identity:
        return identityFails
            ? response({}, 503)
            : response([
                teacher,
                {...teacher, 'userId': 'student', 'role': 'Student'},
                {...teacher, 'userId': 'suspended', 'isSuspended': true},
              ]);
      case final path when path == FixtureRoutes.officeHours:
        expect(request.url.queryParameters['teacherId'], 'teacher');
        return scheduleFails
            ? response({}, 503)
            : response([
                {
                  'id': 'h',
                  'teacherRefId': 'teacher',
                  'dayOfWeek': 'Monday',
                  'startTime': '09:00',
                  'endTime': '12:00',
                  'structureRefId': 'place',
                },
              ]);
      case final path when path == ApiEndpoints.structureDetail('place'):
        return campusFails
            ? response({}, 503)
            : response({
                'id': 'place',
                'name': 'Sala real',
                'campusId': 'campus',
                'categoryId': 'category',
              });
      default:
        throw StateError('Consulta inesperada');
    }
  }

  Future<void> open(WidgetTester tester) async {
    identityFails = scheduleFails = campusFails = false;
    calls.clear();
    session = SessionController(storage: MemoryStorage());
    await account(session, 'viewer', 'Student');
    ApiClientProvider.initialize(session, innerClient: MockClient(handle));
    await tester.pumpWidget(const MaterialApp(home: ProfessorsScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    ApiClientProvider.reset();
  }

  for (final query in ['  Grace  ', ' GRACE@UCT.CL ']) {
    testWidgets('buscar $query conserva datos reales y roles', (tester) async {
      await open(tester);
      expect(find.text('Docente Grace'), findsOneWidget);
      expect(calls.where((p) => p == FixtureRoutes.officeHours).length, 1);
      await tester.enterText(find.byType(TextField), query);
      await tester.pump();
      expect(find.text('Docente Grace'), findsOneWidget);
      await close(tester);
    });
  }

  for (final failure in ['Identity', 'Schedule']) {
    testWidgets('fallo de $failure distingue error de vacío y reintenta', (
      tester,
    ) async {
      await open(tester);
      identityFails = failure == 'Identity';
      scheduleFails = failure == 'Schedule';
      await tester.tap(find.byTooltip('Actualizar directorio'));
      await tester.pumpAndSettle();
      expect(find.text('El directorio no está disponible.'), findsOneWidget);
      expect(find.text('No se encontraron profesores.'), findsNothing);
      identityFails = scheduleFails = false;
      await tester.tap(find.byTooltip('Reintentar carga'));
      await tester.pumpAndSettle();
      expect(find.text('Docente Grace'), findsOneWidget);
      await close(tester);
    });
  }

  testWidgets('Campus fallido conserva ficha y recarga recupera lugares', (
    tester,
  ) async {
    await open(tester);
    campusFails = true;
    await tester.tap(find.byTooltip('Actualizar directorio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente Grace'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('No se pudieron cargar algunos lugares'),
      findsOneWidget,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    campusFails = false;
    await tester.tap(find.byTooltip('Actualizar directorio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente Grace'));
    await tester.pumpAndSettle();
    expect(find.text('Sala real'), findsOneWidget);
    expect(
      find.textContaining('No se pudieron cargar algunos lugares'),
      findsNothing,
    );
    await close(tester);
  });

  test('docente sin atención conserva Identity sin inventar datos', () async {
    session = SessionController(storage: MemoryStorage());
    await account(session, 'viewer', 'Student');
    ApiClientProvider.initialize(session);
    try {
      final source = ScheduleRemoteDataSource(
        client: MockClient(
          (r) async =>
              response(r.url.path == FixtureRoutes.identity ? [teacher] : []),
        ),
      );
      final result = await source.getProfessors();
      expect(result.single.name, 'Docente Grace');
      expect(result.single.officeHours, isEmpty);
      expect(result.single.office, isEmpty);
      expect(result.single.department, isEmpty);
    } finally {
      session.dispose();
      ApiClientProvider.reset();
    }
  });
}
