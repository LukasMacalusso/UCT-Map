import 'dart:async';
import 'dart:convert';

import 'fixture_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/presentation/screens/login/session_required_view.dart';
import 'package:uct_map/presentation/screens/professors/professors_screen.dart';
import 'package:uct_map/presentation/widgets/custom_drawer.dart';

import 'role_fixture.dart';
import 'session_fixture.dart';

class _PendingStorage extends MemoryStorage {
  final pending = Completer<String?>();

  @override
  Future<String?> read() => pending.future;
}

void main() {
  group('Menús por rol', () {
    testWidgets(
      'Student conserva un menú de navegación sin accesos de administración',
      (tester) async {
        final session = await signIn('Student');
        var requests = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((_) async {
            requests++;
            return http.Response('[]', 200);
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              drawer: const CustomDrawer(currentIndex: 0),
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  child: const Text('Abrir'),
                ),
              ),
            ),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        expect(find.text('Administrar usuarios'), findsNothing);
        expect(find.text('Mis horarios y citas'), findsNothing);
        expect(requests, 0);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      },
    );
    for (final entry in [
      ('Teacher', 'Mis horarios y citas'),
      ('Admin', 'Administrar usuarios'),
      ('ObjectsOfficer', 'Gestionar objetos perdidos'),
      ('ComplaintsOfficer', 'Gestionar incidentes'),
    ]) {
      testWidgets('${entry.$1} encuentra su apartado en el drawer', (
        tester,
      ) async {
        final session = await signIn(entry.$1);
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((_) async => http.Response('[]', 200)),
        );
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: CustomDrawer(currentIndex: 0))),
        );
        await tester.pumpAndSettle();
        expect(find.text(entry.$2), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      });
    }
    testWidgets(
      'profesor carga horario y citas reales del contrato y pierde el contenido al cerrar sesión',
      (tester) async {
        final session = await signIn('Teacher');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((request) async {
            if (request.url.path.endsWith('workload')) {
              return http.Response(
                jsonEncode({
                  'teacherRefId': 'user',
                  'from': request.url.queryParameters['from'],
                  'to': request.url.queryParameters['to'],
                  'weeklyOfficeHourMinutes': 180,
                  'meetingCount': 0,
                  'meetings': [],
                  'officeHours': [
                    {
                      'id': 'h',
                      'teacherRefId': 'user',
                      'dayOfWeek': 'Monday',
                      'startTime': '09:00:00',
                      'endTime': '12:00:00',
                    },
                  ],
                }),
                200,
              );
            }
            if (request.url.path.endsWith('office-hours'))
              return http.Response(
                jsonEncode([
                  {
                    'id': 'h',
                    'teacherRefId': 'user',
                    'dayOfWeek': 'Monday',
                    'startTime': '09:00:00',
                    'endTime': '12:00:00',
                  },
                ]),
                200,
              );
            if (request.url.path == FixtureRoutes.identity)
              return http.Response('[]', 200);
            expect(request.url.queryParameters['teacherId'], 'user');
            return http.Response('[]', 200);
          }),
        );
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('Inicio')),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        );
        navigator.currentState!.pushNamed(AppRoutes.teacherSchedule);
        await tester.pumpAndSettle();
        expect(find.text('Lunes'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Sin citas registradas.'),
          150,
        );
        expect(find.text('Sin citas registradas.'), findsOneWidget);
        await session.signOut();
        await tester.pumpAndSettle();
        expect(find.text('Lunes'), findsNothing);
        expect(find.textContaining('inicia sesión'), findsWidgets);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      },
    );
    testWidgets(
      'reserva fuera del horario docente no envía ninguna petición de creación',
      (tester) async {
        final session = await signIn('Student');
        var posts = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((request) async {
            if (request.method == 'POST') {
              posts++;
              return http.Response('{}', 500);
            }
            if (request.method == 'GET' &&
                request.url.path == ApiEndpoints.scheduleMeetings)
              return http.Response('[]', 200);
            if (request.url.path.contains('/students/'))
              return http.Response('{"meetings":[]}', 200);
            if (request.url.path == FixtureRoutes.identity)
              return http.Response(
                jsonEncode([
                  {
                    'userId': 'teacher',
                    'name': 'Docente de prueba',
                    'email': 'teacher@uct.cl',
                    'role': 'Teacher',
                  },
                ]),
                200,
              );
            return http.Response(
              jsonEncode([
                {
                  'id': 'h',
                  'teacherRefId': 'teacher',
                  'dayOfWeek':
                      DateTime.now().add(const Duration(days: 1)).weekday % 7,
                  'startTime': '09:00:00',
                  'endTime': '09:30:00',
                },
              ]),
              200,
            );
          }),
        );
        await tester.pumpWidget(const MaterialApp(home: ProfessorsScreen()));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Docente de prueba'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Agendar Cita'));
        await tester.tap(find.text('Agendar Cita'));
        await tester.pumpAndSettle();
        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('10:00'), findsNothing);
        expect(posts, 0);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      },
    );
    testWidgets(
      'entrada Linux de pruebas inicia sin Mapbox y retira accesos al cerrar sesión',
      (tester) async {
        final session = await signIn('Teacher');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((_) async => http.Response('[]', 200)),
        );
        await tester.pumpWidget(const ManualRolesApp());
        await tester.pumpAndSettle();
        expect(find.text('Mis horarios y citas'), findsOneWidget);
        expect(find.text('Administrar usuarios'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cerrar sesión'));
        await tester.pumpAndSettle();
        expect(find.text('Mis horarios y citas'), findsNothing);
        expect(find.textContaining('inicia sesión'), findsWidgets);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      },
    );
  });

  group('Protección de rutas', () {
    tearDown(ApiClientProvider.reset);

    const restrictedRoutes = {
      AppRoutes.myMeetings: {'Student'},
      AppRoutes.teacherSchedule: {'Teacher'},
      AppRoutes.manageUsers: {'Admin'},
      AppRoutes.manageUserDetail: {'Admin'},
      AppRoutes.manageCampus: {'Admin'},
      AppRoutes.manageObjects: {'ObjectsOfficer'},
      AppRoutes.manageReports: {'ComplaintsOfficer'},
      AppRoutes.objectHeatmap: {'ObjectsOfficer', 'Admin'},
      AppRoutes.reportHeatmap: {'ComplaintsOfficer', 'Admin'},
    };

    for (final role in [
      'Invitado',
      'Student',
      'Teacher',
      'Admin',
      'ObjectsOfficer',
      'ComplaintsOfficer',
    ]) {
      testWidgets('$role no inicia consultas en rutas denegadas', (
        tester,
      ) async {
        final session = role == 'Invitado'
            ? SessionController(storage: MemoryStorage())
            : await signIn(role);
        var requests = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((_) async {
            requests++;
            return http.Response('', 500);
          }),
        );
        final navigator = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        );
        for (final entry in restrictedRoutes.entries) {
          if (entry.value.contains(role)) continue;
          navigator.currentState!.pushNamed(entry.key);
          await tester.pumpAndSettle();
          expect(
            role == 'Invitado'
                ? find.byKey(const ValueKey('authGateLoginButton'))
                : find.text('Tu rol no tiene acceso a esta sección.'),
            findsOneWidget,
            reason: entry.key,
          );
          expect(requests, 0, reason: entry.key);
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
        }
        expect(requests, 0);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      });
    }

    testWidgets('no monta el destino privado durante la restauración', (
      tester,
    ) async {
      final storage = _PendingStorage();
      final session = SessionController(storage: storage);
      ApiClientProvider.initialize(session);
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: SessionRequiredView(
            builder: (_) {
              builds++;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(builds, 0);
      storage.pending.complete(null);
      await tester.pumpAndSettle();
      expect(builds, 0);
      expect(find.byKey(const ValueKey('authGateLoginButton')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
    });

    testWidgets(
      'renovar sesión con el mismo ID desmonta el contenido anterior',
      (tester) async {
        final session = await signIn('Student');
        final replacement = await signIn('Teacher');
        ApiClientProvider.initialize(session);
        await tester.pumpWidget(
          MaterialApp(
            home: SessionRequiredView(
              builder: (_) => const Scaffold(body: TextField()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'borrador anterior');
        await session.signInReal(
          AuthLoginResult(
            userId: 'user',
            email: 'user@uct.cl',
            token: replacement.token!,
          ),
        );
        replacement.dispose();
        await tester.pumpAndSettle();
        expect(find.text('borrador anterior'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      },
    );

    testWidgets(
      'el acceso en una pantalla estrecha permite desplazar al 200 %',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = SessionController(storage: MemoryStorage());
        ApiClientProvider.initialize(session);
        try {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: child!,
              ),
              home: SessionRequiredView(builder: (_) => const SizedBox()),
            ),
          );
          await tester.pumpAndSettle();
          final login = find.byKey(const ValueKey('authGateLoginButton'));
          await tester.ensureVisible(login);
          await tester.pumpAndSettle();
          expect(login.hitTestable(), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          session.dispose();
        }
      },
    );

    for (final status in [400, 401, 403]) {
      testWidgets('Mis citas distingue HTTP $status', (tester) async {
        final session = await signIn('Student');
        var agendaRequests = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((request) async {
            expect(request.url.path, FixtureRoutes.studentMeetings('user'));
            agendaRequests++;
            return http.Response('{"title":"Detalle interno"}', status);
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.myMeetings,
            home: const Scaffold(),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();
        expect(agendaRequests, 1);
        expect(session.isAuthenticated, status != 401);
        expect(switch (status) {
          400 => find.text('No se pudieron cargar tus citas.'),
          401 => find.byKey(const ValueKey('authGateLoginButton')),
          _ => find.text('No tienes permiso para acceder a estos datos.'),
        }, findsOneWidget);
        expect(find.text('Detalle interno'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
      });
    }
  });
}
