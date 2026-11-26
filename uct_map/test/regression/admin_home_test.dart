import 'fixture_routes.dart';

import 'package:uct_map/main.dart';

import 'test_fonts.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/managed_user.dart';
import 'package:uct_map/domain/repositories/identity_repository.dart';
import 'package:uct_map/presentation/screens/home/admin_home_screen.dart';
import 'package:uct_map/presentation/screens/roles/admin_users_screen.dart';
import 'package:uct_map/presentation/navigation/main_navigation_screen.dart';

import '../helpers/mock_mapbox_platform.dart';
import 'session_fixture.dart' as roles;

const users = [
  {
    'userId': 'a',
    'name': 'Ana',
    'email': 'a@example.test',
    'role': 'Admin',
    'isSuspended': false,
  },
  {
    'userId': 's',
    'name': 'Sol',
    'email': 's@example.test',
    'role': 'Student',
    'isSuspended': true,
  },
];

class _PendingIdentity implements IdentityRepository {
  final pending = Completer<List<ManagedUser>>();
  @override
  Future<List<ManagedUser>> getUsers() => pending.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    setupMockMapboxPlatform();
    await loadUiFonts();
  });
  testWidgets(
    'Admin restaura inicio, usa datos completos y vuelve de usuarios sin reiniciar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      debugDisableShadows = false;
      final session = await roles.signIn('Admin');
      var reads = 0;
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient((r) async {
          if (r.url.path == FixtureRoutes.identity) {
            reads++;
            return http.Response(jsonEncode(users), 200);
          }
          return http.Response('[]', 200);
        }),
      );
      await tester.pumpWidget(
        const RepaintBoundary(
          key: ValueKey('admin-capture'),
          child: UctMapApp(),
        ),
      );
      await tester.pumpAndSettle();
      debugDisableShadows = true;
      final shell = tester.state(find.byType(MainNavigationScreen));
      expect(find.text('Inicio administración'), findsOneWidget);
      expect(find.text('2 cuentas registradas'), findsOneWidget);
      expect(find.text('Activas: 1'), findsOneWidget);
      expect(find.text('Suspendidas: 1'), findsOneWidget);
      expect(find.text('Gestionar objetos perdidos'), findsNothing);
      await tester.ensureVisible(find.text('Gestionar usuarios'));
      await tester.tap(find.text('Gestionar usuarios'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminUsersScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(MainNavigationScreen)), same(shell));
      expect(reads, 3);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    },
  );
  testWidgets('un destino de mapa explícito no se convierte en Inicio Admin', (
    tester,
  ) async {
    final session = await roles.signIn('Admin');
    ApiClientProvider.initialize(
      session,
      innerClient: MockClient((_) async => http.Response('[]', 200)),
    );
    await tester.pumpWidget(
      const MaterialApp(home: MainNavigationScreen(initialIndex: 0)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mapa del Campus'), findsOneWidget);
    expect(find.text('Gestionar usuarios'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    ApiClientProvider.reset();
    session.dispose();
  });
  testWidgets('error de resumen no se muestra como cero y puede reintentarse', (
    tester,
  ) async {
    final session = await roles.signIn('Admin');
    var failure = true;
    ApiClientProvider.initialize(
      session,
      innerClient: MockClient(
        (_) async => http.Response(failure ? '{}' : '[]', failure ? 500 : 200),
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdminHomeScreen())),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudo cargar el resumen de usuarios.'),
      findsOneWidget,
    );
    expect(find.text('0 cuentas registradas'), findsNothing);
    failure = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('0 cuentas registradas'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    ApiClientProvider.reset();
    session.dispose();
  });
  testWidgets('gestión existente reintenta sin devolver un Future a setState', (
    tester,
  ) async {
    final session = await roles.signIn('Admin');
    var failure = true;
    ApiClientProvider.initialize(
      session,
      innerClient: MockClient(
        (_) async => http.Response(failure ? '{}' : '[]', failure ? 500 : 200),
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: AdminUsersScreen()));
    await tester.pumpAndSettle();
    expect(
      find.text('No se pudieron cargar usuarios. Reintentar'),
      findsOneWidget,
    );
    failure = false;
    await tester.tap(find.text('No se pudieron cargar usuarios. Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('No hay usuarios.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    ApiClientProvider.reset();
    session.dispose();
  });
  testWidgets(
    'Student no carga datos Admin y logout descarta respuesta pendiente',
    (tester) async {
      var session = await roles.signIn('Student');
      var requests = 0;
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient((_) async {
          requests++;
          return http.Response('[]', 200);
        }),
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AdminHomeScreen())),
      );
      await tester.pumpAndSettle();
      expect(requests, 0);
      expect(find.text('Gestionar usuarios'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
      session = await roles.signIn('Admin');
      ApiClientProvider.initialize(session);
      final repository = _PendingIdentity();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AdminHomeScreen(repository: repository)),
        ),
      );
      await tester.pump();
      await session.signOut();
      await tester.pumpAndSettle();
      repository.pending.complete([
        const ManagedUser(
          id: 'a',
          name: 'Ana',
          email: 'a@example.test',
          role: 'Admin',
          isSuspended: false,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('1 cuentas registradas'), findsNothing);
      expect(find.text('Gestionar usuarios'), findsNothing);
      expect(find.byKey(const ValueKey('authGateLoginButton')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    },
  );
}
