import 'test_fonts.dart' show loadUiFonts;

import 'dart:async';

import 'package:uct_map/application/session/session_controller.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/presentation/navigation/main_navigation_screen.dart';
import 'package:uct_map/core/navigation/app_routes.dart';

import '../helpers/mock_mapbox_platform.dart';
import 'session_fixture.dart' as roles;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/presentation/screens/home/student_home_screen.dart';
import 'package:uct_map/presentation/screens/map/widgets/campus_search_sheet.dart';

void main() {
  setUpAll(() async {
    setupMockMapboxPlatform();
    await loadUiFonts();
  });
  for (final explicit in [false, true]) {
    testWidgets('Student restaura sesión: destino explícito=$explicit', (
      tester,
    ) async {
      final session = await roles.signIn('Student');
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (request) async => http.Response(
            request.url.path.contains('/students/')
                ? jsonEncode({'studentRefId': 'user', 'meetings': []})
                : '[]',
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: explicit
              ? const MainNavigationScreen()
              : const SessionLandingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(
        find.text('Próxima consulta'),
        explicit ? findsNothing : findsOneWidget,
      );
      expect(bar.selectedIndex, explicit ? 1 : 0);
      await session.signOut();
      await tester.pumpAndSettle();
      if (explicit) {
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .destinations
              .length,
          5,
        );
      }
      expect(find.text('Próxima consulta'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
  }

  testWidgets(
    'dashboard abre citas en ruta independiente sin accesos redundantes',
    (tester) async {
      final session = await roles.signIn('Student');
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (request) async => http.Response(
            request.url.path.contains('/students/')
                ? jsonEncode({'studentRefId': 'user', 'meetings': []})
                : '[]',
            200,
          ),
        ),
      );
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? route;
      Object? args;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF003865),
              primary: const Color(0xFF003865),
            ),
          ),
          home: const RepaintBoundary(
            key: ValueKey('dashboard-capture'),
            child: StudentHomeScreen(),
          ),
          onGenerateRoute: (settings) {
            route = settings.name;
            args = settings.arguments;
            return MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: Text('Apartado independiente')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Próxima consulta'), findsOneWidget);
      expect(
        find.text(
          'No tienes consultas próximas. Puedes consultar la atención disponible en el directorio.',
        ),
        findsOneWidget,
      );
      expect(find.text('Buscar edificio, sala o servicio'), findsNothing);
      expect(find.text('Consultar directorio docente'), findsNothing);
      await tester.tap(find.text('Ver mis citas'));
      await tester.pumpAndSettle();
      expect(route, AppRoutes.myMeetings);
      expect(args, isNull);
      expect(find.text('Apartado independiente'), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Próxima consulta'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    },
  );
  testWidgets(
    'Perfil invitado permite login y abre dashboard Student independiente',
    (tester) async {
      final signed = await roles.signIn('Student');
      final token = signed.token!;
      signed.dispose();
      final session = SessionController(storage: roles.MemoryStorage());
      await session.ready;
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (request) async => http.Response(
            request.url.path.contains('/students/')
                ? jsonEncode({'studentRefId': 'user', 'meetings': []})
                : '[]',
            200,
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: const MainNavigationScreen(initialIndex: 4),
          onGenerateRoute: (settings) {
            if (settings.name == '/login')
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.pop(context, {
                      'ok': true,
                      'userId': 'user',
                      'email': 'user@uct.cl',
                      'token': token,
                    }),
                    child: const Text('Autenticar fixture'),
                  ),
                ),
              );
            return AppRoutes.onGenerateRoute(settings);
          },
        ),
      );
      await tester.pumpAndSettle();
      final shell = tester.state(find.byType(MainNavigationScreen));
      expect(find.byKey(const ValueKey('authGateLoginButton')), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('authGateLoginButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Autenticar fixture'));
      await tester.pumpAndSettle();
      expect(find.text('Próxima consulta'), findsOneWidget);
      expect(tester.state(find.byType(MainNavigationScreen)), same(shell));
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    },
  );
  testWidgets(
    'vaciar consulta pendiente detiene carga y descarta respuesta antigua',
    (tester) async {
      final response = Completer<List<dynamic>>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampusSearchSheet(
              buildings: const [],
              structures: const [],
              embedded: true,
              searchRooms: (_) => response.future,
              loadCategories: () async => [],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'sala');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byType(LinearProgressIndicator), findsNothing);
      response.complete([]);
      await tester.pump();
      expect(find.text('No se encontraron resultados.'), findsNothing);
    },
  );
}
