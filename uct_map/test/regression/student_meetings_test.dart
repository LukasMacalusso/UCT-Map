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
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/schedule_meeting.dart';
import 'package:uct_map/presentation/screens/roles/student_meetings_screen.dart';

import 'session_fixture.dart' show MemoryStorage, account;

void main() {
  setUpAll(() async {
    await loadUiFonts();
  });
  Map<String, dynamic> meeting({
    String owner = 'student',
    int duration = 45,
    String? structure = 'place',
  }) {
    final now = DateTime.now();
    return {
      'id': 'm',
      'teacherRefId': 'teacher',
      'studentRefId': owner,
      'structureRefId': structure,
      'scheduledAt': DateTime(
        now.year,
        now.month,
        now.day + 1,
        14,
        30,
      ).toUtc().toIso8601String(),
      'durationMinutes': duration,
      'status': 'Pending',
    };
  }

  http.Response json(Object data, [int status = 200]) =>
      http.Response(jsonEncode(data), status);
  http.Response metadata(http.Request request) {
    if (request.url.path == FixtureRoutes.identity) {
      return json([
        {
          'userId': 'teacher',
          'name': 'Docente de prueba',
          'email': 'docente@uct.cl',
          'role': 'Teacher',
        },
      ]);
    }
    if (request.url.path == ApiEndpoints.structureDetail('place')) {
      return json({
        'id': 'place',
        'name': 'Sala de consulta',
        'campusId': 'campus',
        'categoryId': 'category',
      });
    }
    throw StateError('Consulta inesperada: ${request.url.path}');
  }

  late SessionController session;
  var created = false;
  setUp(() {
    created = false;
  });
  tearDown(() {
    if (created) session.dispose();
    ApiClientProvider.reset();
  });
  Future<void> setup(
    String? role,
    Future<http.Response> Function(http.Request) handle,
  ) async {
    session = SessionController(storage: MemoryStorage());
    created = true;
    await session.ready;
    if (role != null) await account(session, 'student', role);
    ApiClientProvider.initialize(session, innerClient: MockClient(handle));
  }

  Future<void> cleanup(WidgetTester tester) async {
    debugDisableShadows = true;
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    created = false;
  }

  Future<void> screen(
    WidgetTester tester, {
    RouteFactory? routes,
    double textScale = 1,
  }) async {
    debugDisableShadows = false;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        onGenerateRoute: routes ?? AppRoutes.onGenerateRoute,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF003865),
            primary: const Color(0xFF003865),
          ),
        ),
        initialRoute: '/student-test',
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute(
            builder: (_) => const RepaintBoundary(
              key: ValueKey('student-capture'),
              child: StudentMeetingsScreen(),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'modelo conserva duración, fin y ubicación nula sin inventar valores',
    () {
      final data = meeting(structure: null);
      final value = ScheduleMeeting.fromJson(data);
      expect(value.structureRefId, isNull);
      expect(value.durationMinutes, 45);
      expect(value.endsAt.difference(value.scheduledAt).inMinutes, 45);
      expect(value.toJson()['durationMinutes'], 45);
      for (final invalid in [null, 0, -1, '30']) {
        expect(
          () => ScheduleMeeting.fromJson({...data, 'durationMinutes': invalid}),
          throwsFormatException,
        );
      }
    },
  );

  testWidgets(
    'mis citas consulta solo al estudiante actual y muestra nombres y duración reales',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await setup('Student', (request) async {
        if (request.url.path == FixtureRoutes.studentMeetings('student')) {
          expect(request.url.queryParameters.keys, containsAll(['from', 'to']));
          return json({
            'studentRefId': 'student',
            'meetings': [meeting()],
          });
        }
        return metadata(request);
      });
      await screen(tester);
      expect(find.text('Docente de prueba'), findsOneWidget);
      expect(find.text('Sala de consulta'), findsOneWidget);
      expect(find.text('45 minutos'), findsOneWidget);
      expect(find.textContaining('14:30 – 15:15'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      await cleanup(tester);
    },
  );

  for (final (width, scale) in [(320.0, 2.0), (412.0, 1.0), (1000.0, 1.0)]) {
    testWidgets(
      'agenda agrupa días y conserva acciones a $width con escala $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final first = meeting();
        final nextDay = DateTime.parse(first['scheduledAt'] as String)
            .add(const Duration(days: 1));
        await setup('Student', (request) async {
          if (request.url.path.contains('/schedule/')) {
            return json({
              'studentRefId': 'student',
              'meetings': [
                first,
                {...first, 'id': 'm2', 'status': 'Confirmed'},
                {
                  ...first,
                  'id': 'm3',
                  'scheduledAt': nextDay.toIso8601String(),
                  'status': 'Cancelled',
                },
              ],
            });
          }
          return metadata(request);
        });
        await screen(tester, textScale: scale);
        expect(tester.takeException(), isNull);
        final dates = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(
                r'^(Lunes|Martes|Miércoles|Jueves|Viernes|Sábado|Domingo) ',
              ).hasMatch(widget.data ?? ''),
        );
        final firstDate = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(
                r'^(Lunes|Martes|Miércoles|Jueves|Viernes|Sábado|Domingo) ',
              ).hasMatch(widget.data ?? '') &&
              (widget.data ?? '').contains(
                '${DateTime.parse(first['scheduledAt'] as String).day} de',
              ),
        );
        await tester.scrollUntilVisible(
          firstDate,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(dates, findsWidgets);
        final firstDayLabel = (tester.widget<Text>(dates.first)).data!;
        expect(
          firstDayLabel,
          contains('${DateTime.parse(first['scheduledAt'] as String).day} de'),
        );
        expect(find.text('Agendar consulta').hitTestable(), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Cancelada'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Cancelada').hitTestable(), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                RegExp(
                  r'^(Lunes|Martes|Miércoles|Jueves|Viernes|Sábado|Domingo) ',
                ).hasMatch(widget.data ?? '') &&
                (widget.data ?? '').contains('${nextDay.day} de'),
          ),
          findsOneWidget,
        );
        expect(find.text('Agendar consulta').hitTestable(), findsOneWidget);
        if (width == 412) {
          await tester.drag(find.byType(ListView), const Offset(0, 2000));
          await tester.pumpAndSettle();
        }
        await cleanup(tester);
      },
    );
  }

  testWidgets(
    'vacío no se confunde con fallo y no consulta metadatos innecesarios',
    (tester) async {
      await setup('Student', (request) async {
        expect(request.url.path, FixtureRoutes.studentMeetings('student'));
        return json({'studentRefId': 'student', 'meetings': []});
      });
      await screen(tester);
      expect(
        find.text('Aún no tienes citas para este período.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsNothing);
      await cleanup(tester);
    },
  );
  testWidgets(
    'fallo muestra reintento y recupera citas sin mostrarlas como vacío',
    (tester) async {
      var fail = true;
      await setup('Student', (request) async {
        if (request.url.path.contains('/schedule/')) {
          return fail
              ? json({}, 503)
              : json({'studentRefId': 'student', 'meetings': []});
        }
        return metadata(request);
      });
      await screen(tester);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Aún no tienes citas para este período.'), findsNothing);
      fail = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Aún no tienes citas para este período.'),
        findsOneWidget,
      );
      await cleanup(tester);
    },
  );
  testWidgets(
    'metadatos caídos conservan la cita y explican los nombres faltantes',
    (tester) async {
      await setup(
        'Student',
        (request) async => request.url.path.contains('/schedule/')
            ? json({
                'studentRefId': 'student',
                'meetings': [meeting()],
              })
            : json({}, 503),
      );
      await screen(tester);
      expect(find.text('45 minutos'), findsOneWidget);
      expect(find.text('Nombre del docente no disponible'), findsOneWidget);
      expect(find.textContaining('No se pudieron obtener'), findsOneWidget);
      await cleanup(tester);
    },
  );
  testWidgets('no presenta citas pertenecientes a otro estudiante', (
    tester,
  ) async {
    await setup(
      'Student',
      (_) async => json({
        'studentRefId': 'student',
        'meetings': [meeting(owner: 'other')],
      }),
    );
    await screen(tester);
    expect(
      find.text('No tienes permiso para acceder a estos datos.'),
      findsOneWidget,
    );
    expect(find.text('45 minutos'), findsNothing);
    await cleanup(tester);
  });

  for (final map in [false, true]) {
    testWidgets(
      'regreso del directorio ${map ? "abre mapa" : "actualiza citas"}',
      (tester) async {
        var calls = 0;
        await setup('Student', (request) async {
          if (request.url.path.contains('/schedule/')) {
            calls++;
            return json({
              'studentRefId': 'student',
              'meetings': calls == 1 ? [] : [meeting()],
            });
          }
          return metadata(request);
        });
        await screen(
          tester,
          routes: (settings) {
            if (settings.name == AppRoutes.professors) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.pop(context, map ? 0 : null),
                    child: const Text('Volver al listado'),
                  ),
                ),
              );
            }
            if (settings.name == AppRoutes.initial) {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(body: Text('Mapa esperado')),
              );
            }
            return null;
          },
        );
        await tester.tap(find.text('Agendar consulta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Volver al listado'));
        await tester.pumpAndSettle();
        if (map) {
          expect(find.text('Mapa esperado'), findsOneWidget);
          expect(calls, 1);
        } else {
          expect(find.text('Docente de prueba'), findsOneWidget);
          expect(calls, 2);
        }
        await cleanup(tester);
      },
    );
  }
  for (final role in <String?>[
    null,
    'Teacher',
    'Admin',
    'ObjectsOfficer',
    'ComplaintsOfficer',
  ]) {
    testWidgets('ruta directa se protege para $role sin llamadas de agenda', (
      tester,
    ) async {
      var calls = 0;
      await setup(role, (_) async {
        calls++;
        return json({}, 500);
      });
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.myMeetings),
                child: const Text('Abrir citas'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abrir citas'));
      await tester.pumpAndSettle();
      expect(find.text('Tu agenda'), findsNothing);
      expect(calls, 0);
      await cleanup(tester);
    });
  }
  testWidgets(
    'cierre de sesión durante carga descarta el resultado pendiente',
    (tester) async {
      final gate = Completer<http.Response>();
      await setup('Student', (_) async => gate.future);
      await tester.pumpWidget(const MaterialApp(home: StudentMeetingsScreen()));
      await tester.pump();
      await session.signOut();
      gate.complete(
        json({
          'studentRefId': 'student',
          'meetings': [meeting()],
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('45 minutos'), findsNothing);
      expect(find.textContaining('inicia sesión'), findsWidgets);
      await cleanup(tester);
    },
  );
}
