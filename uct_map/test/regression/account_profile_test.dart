import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'fixture_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/managed_user.dart';
import 'package:uct_map/domain/repositories/identity_repository.dart';
import 'package:uct_map/presentation/screens/profile/profile_screen.dart';
import 'package:uct_map/presentation/screens/profile/profile_settings_screen.dart';
import 'package:uct_map/presentation/screens/roles/teacher_schedule_screen.dart';

import 'session_fixture.dart' as roles;
import 'session_fixture.dart' show MemoryStorage, account;
import 'test_fonts.dart' show loadUiFonts;

class ProfileRepository implements IdentityRepository {
  final pending = Completer<ManagedUser>();
  String? requested;
  @override
  Future<ManagedUser> getUserById(String id) {
    requested = id;
    return pending.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Perfil propio', () {
    testWidgets(
      'perfil carga cuenta propia y descarta respuesta después de logout',
      (tester) async {
        final session = await roles.signIn('Student');
        addTearDown(session.dispose);
        final repo = ProfileRepository();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProfileScreen(session: session, repository: repo),
            ),
          ),
        );
        await tester.pump();
        expect(repo.requested, session.currentUser!.id);
        final user = session.currentUser!;
        await session.signOut();
        repo.pending.complete(
          ManagedUser(
            id: user.id,
            name: 'Nombre anterior',
            email: user.email,
            role: 'Student',
            isSuspended: false,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Nombre anterior'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        await session.signOut();
      },
    );
    testWidgets('perfil muestra nombre real y mantiene permisos de sesión', (
      tester,
    ) async {
      final session = await roles.signIn('Student');
      addTearDown(session.dispose);
      final repo = ProfileRepository();
      final user = session.currentUser!;
      repo.pending.complete(
        ManagedUser(
          id: user.id,
          name: 'Nombre del servicio',
          email: user.email,
          role: 'Student',
          isSuspended: false,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileScreen(session: session, repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nombre del servicio'), findsOneWidget);
      expect(session.currentUser, same(user));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.signOut();
    });
  });

  group('Vistas del perfil', () {
    setUpAll(loadUiFonts);
    for (final (name, scale) in [
      ('teacher', 1.0),
      ('teacher', 2.0),
      ('profile', 2.0),
    ]) {
      testWidgets('$name jerarquía y texto $scale sin solapamientos', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 950));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final semantics = tester.ensureSemantics();

        final session = await roles.signIn('Teacher');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((request) async {
            Object data = [];
            if (request.url.path.endsWith('workload')) {
              data = {
                'teacherRefId': 'user',
                'from': request.url.queryParameters['from'],
                'to': request.url.queryParameters['to'],
                'weeklyOfficeHourMinutes': 900,
                'meetingCount': 1,
                'officeHours': [],
                'meetings': [
                  {
                    'id': 'm',
                    'teacherRefId': 'user',
                    'studentRefId': 'student',
                    'structureRefId': null,
                    'scheduledAt': DateTime.now()
                        .add(const Duration(days: 1))
                        .toIso8601String(),
                    'durationMinutes': 30,
                    'status': 'Pending',
                  },
                ],
              };
            } else if (request.url.path == FixtureRoutes.identity) {
              data = [
                {
                  'userId': 'student',
                  'name': 'Estudiante de consulta',
                  'email': 'student@uct.cl',
                  'role': 'Student',
                },
              ];
            }
            return http.Response(jsonEncode(data), 200);
          }),
        );
        final repository = ProfileRepository();
        repository.pending.complete(
          const ManagedUser(
            id: 'user',
            name: 'Docente del servicio',
            email: 'user@uct.cl',
            role: 'Teacher',
            isSuspended: false,
          ),
        );
        final capture = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: name == 'teacher'
                  ? const TeacherScheduleScreen()
                  : Scaffold(
                      body: ProfileScreen(
                        session: session,
                        repository: repository,
                      ),
                    ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (name == 'teacher') {
          await tester.scrollUntilVisible(
            find.text('Acciones'),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final action = tester
              .getSemantics(find.text('Acciones'))
              .getSemanticsData();
          expect(action.flagsCollection.isButton, isTrue);
          expect(action.hasAction(ui.SemanticsAction.tap), isTrue);
          await tester.tap(find.text('Acciones'));
          await tester.pumpAndSettle();
          expect(find.text('Confirmar cita'), findsOneWidget);
          expect(find.text('Cancelar cita'), findsOneWidget);
          await tester.tapAt(const Offset(20, 20));
          await tester.pumpAndSettle();
          await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
          await tester.pumpAndSettle();
        }
        await tester.pumpWidget(const SizedBox());
        await session.signOut();
        session.dispose();
        ApiClientProvider.reset();
        semantics.dispose();
      });
    }
  });

  group('Configuración y texto aumentado', () {
    setUpAll(loadUiFonts);
    for (final scale in [1.0, 2.0]) {
      testWidgets('información real de cuenta legible al ${scale * 100} %', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = SessionController(storage: MemoryStorage());
        await session.ready;
        await account(session, 'visual', 'Student');
        ApiClientProvider.initialize(session);
        const capture = ValueKey('profileCapture');
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const ProfileSettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Tu cuenta UCT Map'), findsOneWidget);
        expect(find.text('Acceso y sesión'), findsOneWidget);
        expect(find.byType(SwitchListTile), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      });
    }
  });
}
