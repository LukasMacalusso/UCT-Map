import 'test_fonts.dart' show loadUiFonts;
import 'fixture_routes.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/schedule_meeting.dart';
import 'package:uct_map/presentation/screens/professors/professors_screen.dart';
import 'package:uct_map/presentation/screens/roles/teacher_schedule_screen.dart';

import 'session_fixture.dart' show MemoryStorage, account;

Map<String, dynamic> hour({
  String teacher = 'teacher',
  String day = 'Monday',
  String? structure = 'structure',
}) => {
  'id': 'hour-$day',
  'teacherRefId': teacher,
  'structureRefId': structure,
  'dayOfWeek': day,
  'startTime': '09:00:00',
  'endTime': '12:00:00',
};

Map<String, dynamic> meeting(String id, String status, DateTime date) => {
  'id': id,
  'teacherRefId': 'teacher',
  'studentRefId': id,
  'structureRefId': 'structure',
  'scheduledAt': date.toIso8601String(),
  'durationMinutes': 30,
  'status': status,
};

http.Response jsonResponse(Object value, [int status = 200]) =>
    http.Response(jsonEncode(value), status);

void main() {
  setUpAll(() async {
    await loadUiFonts();
  });
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Horario semanal real', () {
    test('los siete días y domingo se serializan sin perder estructura', () {
      for (final (index, day) in [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ].indexed) {
        final value = OfficeHour.fromJson(hour(day: day));
        expect(value.dayOfWeek, index + 1);
        expect(value.toJson()['dayOfWeek'], (index + 1) % 7);
        final roundTrip = OfficeHour.fromJson(value.toJson());
        expect(roundTrip.dayOfWeek, value.dayOfWeek);
        expect(roundTrip.structureRefId, 'structure');
      }
    });
    test(
      'rechaza horas inválidas, intervalos invertidos y día desconocido',
      () {
        for (final start in [
          '24:00',
          '09:60',
          '9:00',
          '09:00:61',
          '09:00:00.12345678',
        ]) {
          expect(
            () => OfficeHour.fromJson({...hour(), 'startTime': start}),
            throwsFormatException,
          );
        }
        expect(
          () => OfficeHour.fromJson({...hour(), 'endTime': '09:00:00'}),
          throwsFormatException,
        );
        expect(
          () => OfficeHour.fromJson({...hour(), 'dayOfWeek': 'Funday'}),
          throwsFormatException,
        );
      },
    );
    test('incluye el bloque exacto y excluye exceso, día diferente o duración inválida', () {
      final value = OfficeHour.fromJson(hour());
      expect(value.contains(DateTime(2026, 11, 2, 9)), isTrue);
      expect(value.contains(DateTime(2026, 11, 2, 11, 30)), isTrue);
      expect(value.contains(DateTime(2026, 11, 2, 11, 31)), isFalse);
      expect(value.contains(DateTime(2026, 11, 3, 9)), isFalse);
      expect(
        value.contains(DateTime(2026, 11, 2, 9), durationMinutes: 0),
        isFalse,
      );
    });
    test('conserva los segundos y la precisión de TimeOnly al reservar', () {
      final value = OfficeHour.fromJson({
        ...hour(),
        'startTime': '09:00:30.0000001',
        'endTime': '10:00:00',
      });
      expect(value.contains(DateTime(2026, 11, 2, 9)), isFalse);
      expect(value.contains(DateTime(2026, 11, 2, 9, 0, 30)), isFalse);
      expect(value.contains(DateTime(2026, 11, 2, 9, 0, 30, 0, 1)), isTrue);
      expect(value.startLabel, '09:00:30.0000001');
      expect(value.endLabel, '10:00');
    });
    test('una fecha o estado malformado no se convierte en una cita pendiente de hoy', () {
      expect(
        () => ScheduleMeeting.fromJson({
          ...meeting('a', 'Pending', DateTime(2026)),
          'scheduledAt': 'invalid',
        }),
        throwsFormatException,
      );
      expect(
        () => ScheduleMeeting.fromJson(meeting('a', 'Unknown', DateTime(2026))),
        throwsFormatException,
      );
    });
    test(
      'Cancelled de la PR #5 y Completed nunca son próximas citas activas',
      () {
        for (final status in ['Cancelled', 'Completed']) {
          expect(
            ScheduleMeeting.fromJson(meeting('a', status, DateTime(2026)))
                .isActive,
            isFalse,
          );
        }
      },
    );
  });

  late SessionController session;
  var sessionCreated = false;
  setUp(() => sessionCreated = false);
  tearDown(() {
    if (sessionCreated) session.dispose();
    ApiClientProvider.reset();
  });

  Future<void> useClient(
    Future<http.Response> Function(http.Request) handle,
  ) async {
    if (!sessionCreated) {
      session = SessionController(storage: MemoryStorage());
      sessionCreated = true;
    }
    await session.ready;
    if (!session.isAuthenticated) await account(session, 'teacher', 'Teacher');
    ApiClientProvider.initialize(
      session,
      innerClient: MockClient((request) async {
        if (!request.url.path.endsWith('/workload')) return handle(request);
        final teacher = session.currentUser!.id;
        final query = request.url.queryParameters;
        final hours = await handle(
          http.Request(
            'GET',
            request.url.replace(
              path: FixtureRoutes.officeHours,
              queryParameters: {'teacherId': teacher},
            ),
          ),
        );
        if (hours.statusCode != 200) return hours;
        final meetings = await handle(
          http.Request(
            'GET',
            request.url.replace(
              path: ApiEndpoints.scheduleMeetings,
              queryParameters: {...query, 'teacherId': teacher},
            ),
          ),
        );
        if (meetings.statusCode != 200) return meetings;
        final blocks = jsonDecode(hours.body) as List;
        final values = jsonDecode(meetings.body) as List;
        return jsonResponse({
          'teacherRefId': teacher,
          'from': query['from'],
          'to': query['to'],
          'weeklyOfficeHourMinutes': blocks.fold<int>(0, (total, block) {
            int minutes(String clock) =>
                int.parse(clock.substring(0, 2)) * 60 +
                int.parse(clock.substring(3, 5));
            return total +
                minutes(block['endTime'] as String) -
                minutes(block['startTime'] as String);
          }),
          'meetingCount': values.length,
          'officeHours': blocks,
          'meetings': values,
        });
      }),
    );
  }

  Future<void> remove(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    sessionCreated = false;
    ApiClientProvider.reset();
  }

  testWidgets(
    'diseño docente con nombres y sala reales, canceladas fuera de próxima cita',
    (tester) async {
      final now = DateTime.now();
      final boundary = GlobalKey();
      await useClient((request) async {
        switch (request.url.path) {
          case final path when path == FixtureRoutes.officeHours:
            expect(request.url.queryParameters['teacherId'], 'teacher');
            return jsonResponse([hour()]);
          case ApiEndpoints.scheduleMeetings:
            expect(request.url.queryParameters['teacherId'], 'teacher');
            return jsonResponse([
              meeting(
                'cancelled',
                'Cancelled',
                now.add(const Duration(hours: 1)),
              ),
              meeting(
                'completed',
                'Completed',
                now.add(const Duration(hours: 2)),
              ),
              meeting('active', 'Pending', now.add(const Duration(days: 1))),
            ]);
          case final path when path == FixtureRoutes.identity:
            return jsonResponse([
              {
                'userId': 'teacher',
                'name': 'Docente de prueba',
                'email': 'teacher@uct.cl',
                'role': 'Teacher',
              },
              {
                'userId': 'active',
                'name': 'Estudiante activo',
                'email': 'active@uct.cl',
                'role': 'Student',
              },
            ]);
          case final path
              when path == ApiEndpoints.structureDetail('structure'):
            return jsonResponse({
              'id': 'structure',
              'name': 'Sala de consultas',
            });
          default:
            fail('Ruta no esperada: ${request.url.path}');
        }
      });
      debugDisableShadows = true;
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF003865),
                primary: const Color(0xFF003865),
                secondary: const Color(0xFFEAA221),
              ),
              appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            ),
            home: const TeacherScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.text('Docente de prueba'), findsNothing);
      expect(find.text('teacher@uct.cl'), findsNothing);
      expect(find.text('Estudiante: Estudiante activo'), findsOneWidget);
      expect(find.text('Sala de consultas'), findsWidgets);
      expect(find.textContaining('Cátedra'), findsNothing);
      await tester.scrollUntilVisible(find.text('Cancelada'), 200);
      expect(find.text('Cancelada'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Horario de atención'), 200);
      await tester.tap(find.text('Horario de atención'));
      await tester.pumpAndSettle();
      expect(find.text('Lunes'), findsOneWidget);
      expect(find.text('09:00 – 12:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      debugDisableShadows = true;
      await remove(tester);
    },
  );

  for (final (width, scale) in [(320.0, 2.0), (1280.0, 1.0)]) {
    testWidgets(
      'citas Teacher legibles a $width con texto $scale y duración real',
      (tester) async {
        await useClient((request) async {
          if (request.url.path.endsWith('office-hours')) {
            return jsonResponse([hour()]);
          }
          if (request.url.path.endsWith('meetings')) {
            return jsonResponse([
              {
                ...meeting(
                  'fixture-student',
                  'Confirmed',
                  DateTime.now().add(const Duration(days: 1)),
                ),
                'durationMinutes': 45,
              },
            ]);
          }
          return jsonResponse([]);
        });
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const TeacherScheduleScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Lunes'), findsNothing);
        await tester.scrollUntilVisible(find.text('45 minutos'), 150);
        expect(find.text('45 minutos'), findsOneWidget);
        expect(find.text('Confirmada'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('No hay más citas en este período.'),
          150,
        );
        expect(find.text('No hay más citas en este período.'), findsOneWidget);
        expect(find.textContaining('fixture-student'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.text('Horario de atención'), 150);
        await tester.tap(find.text('Horario de atención'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Lunes'), 150);
        expect(tester.takeException(), isNull);
        await remove(tester);
      },
    );
  }

  testWidgets(
    'vacíos independientes y ubicación nula; accesible en pantalla estrecha',
    (tester) async {
      await useClient((request) async {
        if (request.url.path.endsWith('office-hours')) {
          return jsonResponse([hour(structure: null)]);
        }
        return jsonResponse([]);
      });
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: const TeacherScheduleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await tester.scrollUntilVisible(find.text('Ubicación no informada'), 150);
      await tester.scrollUntilVisible(find.text('Sin citas registradas.'), 150);
      expect(find.text('Sin citas registradas.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await remove(tester);
    },
  );

  testWidgets('error de Schedule es error con reintento y no agenda vacía', (
    tester,
  ) async {
    var failRequest = true;
    await useClient(
      (request) async => failRequest
          ? jsonResponse({'detail': 'unavailable'}, 503)
          : jsonResponse([]),
    );
    await tester.pumpWidget(const MaterialApp(home: TeacherScheduleScreen()));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(
      find.text('No se pudo cargar la agenda. Reintentar'),
      findsOneWidget,
    );
    expect(find.text('Sin horarios registrados.'), findsNothing);
    failRequest = false;
    await tester.tap(find.text('No se pudo cargar la agenda. Reintentar'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.text('Sin horarios registrados.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sin citas registradas.'), 150);
    expect(find.text('Sin citas registradas.'), findsOneWidget);
    await remove(tester);
  });

  testWidgets(
    'fallo de metadatos mantiene horarios, referencias y aviso explícito',
    (tester) async {
      await useClient((request) async {
        if (request.url.path.endsWith('office-hours')) {
          return jsonResponse([hour()]);
        }
        if (request.url.path.endsWith('meetings')) return jsonResponse([]);
        return jsonResponse({'detail': 'unavailable'}, 503);
      });
      await tester.pumpWidget(const MaterialApp(home: TeacherScheduleScreen()));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(
        find.textContaining('No se pudieron cargar algunos nombres'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Ubicación no disponible'),
        150,
      );
      expect(find.text('Ubicación no disponible'), findsOneWidget);
      await remove(tester);
    },
  );

  testWidgets(
    'cambio de cuenta durante carga descarta respuesta y peticiones antiguas',
    (tester) async {
      final old = Completer<http.Response>();
      final queries = <String>[];
      Map<String, String> oldRange = {};
      Map<String, dynamic> workload(
        String teacher,
        String day,
        Map<String, String> range,
      ) => {
        'teacherRefId': teacher,
        'from': range['from'],
        'to': range['to'],
        'weeklyOfficeHourMinutes': 180,
        'meetingCount': 0,
        'meetings': [],
        'officeHours': [hour(teacher: teacher, day: day, structure: null)],
      };
      await useClient((_) async => jsonResponse([]));
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient((request) async {
          if (request.url.path.endsWith('/workload')) {
            final teacher = request.url.pathSegments[3];
            queries.add('workload:$teacher');
            if (teacher == 'teacher') {
              oldRange = request.url.queryParameters;
              return old.future;
            }
            return jsonResponse(
              workload(teacher, 'Tuesday', request.url.queryParameters),
            );
          }
          queries.add(request.url.path);
          return jsonResponse([]);
        }),
      );
      await tester.pumpWidget(const MaterialApp(home: TeacherScheduleScreen()));
      await tester.pump();
      await account(session, 'new-teacher', 'Teacher');
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.text('new-teacher@uct.cl'), findsNothing);
      old.complete(jsonResponse(workload('teacher', 'Monday', oldRange)));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(queries.where((q) => q.startsWith('workload:')).toList(), [
        'workload:teacher',
        'workload:new-teacher',
      ]);
      expect(queries.where((q) => q == FixtureRoutes.identity), hasLength(1));
      expect(find.text('Lunes'), findsNothing);
      await tester.scrollUntilVisible(find.text('Martes'), 150);
      expect(find.text('Martes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await remove(tester);
    },
  );

  testWidgets('401 durante la carga elimina el panel sin datos residuales', (
    tester,
  ) async {
    await useClient((_) async => jsonResponse({'detail': 'unauthorized'}, 401));
    await tester.pumpWidget(const MaterialApp(home: TeacherScheduleScreen()));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(find.textContaining('inicia sesión'), findsWidgets);
    expect(find.text('Horario de atención'), findsNothing);
    await remove(tester);
  });

  testWidgets('agenda ajena se rechaza aunque el servidor devuelva HTTP 200', (
    tester,
  ) async {
    await useClient(
      (request) async => jsonResponse(
        request.url.path.endsWith('office-hours')
            ? [hour(teacher: 'other')]
            : [],
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: TeacherScheduleScreen()));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
    expect(
      find.text('No tienes permiso para acceder a estos datos.'),
      findsOneWidget,
    );
    expect(find.text('Lunes'), findsNothing);
    await remove(tester);
  });

  testWidgets(
    'directorio muestra bloques semanales sin datos académicos inventados',
    (tester) async {
      session = SessionController(storage: MemoryStorage());
      sessionCreated = true;
      await account(session, 'student', 'Student');
      await useClient((request) async {
        if (request.url.path == FixtureRoutes.identity) {
          return jsonResponse([
            {
              'userId': 'teacher',
              'name': 'Docente real',
              'email': 'teacher@uct.cl',
              'role': 'Teacher',
            },
          ]);
        }
        if (request.url.path.endsWith('office-hours')) {
          return jsonResponse([hour(structure: null)]);
        }
        fail(
          'No debe llamar cancelación ni disponibilidad: ${request.url.path}',
        );
      });
      await tester.pumpWidget(const MaterialApp(home: ProfessorsScreen()));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      await tester.tap(find.text('Docente real'));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
      expect(find.text('Lunes'), findsOneWidget);
      expect(find.text('09:00 – 12:00'), findsOneWidget);
      expect(find.text('Ubicación no informada'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await remove(tester);
    },
  );
}
