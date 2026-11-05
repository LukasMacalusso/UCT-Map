import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter/material.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/presentation/screens/profile/profile_screen.dart';
import 'package:uct_map/presentation/screens/profile/my_reports_screen.dart';
import 'package:uct_map/presentation/screens/profile/my_lost_items_screen.dart';
import 'package:uct_map/presentation/screens/profile/profile_settings_screen.dart';

class _Storage implements TokenStorage {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> save(String token) async {}
  @override
  Future<void> clear() async {}
}

void main() {
  late SessionController session;
  setUp(ApiClientProvider.reset);
  tearDown(() {
    ApiClientProvider.reset();
  });
  Future<void> signIn() async {
    session = SessionController(storage: _Storage());
    await session.ready;
    ApiClientProvider.reset(
      session: session,
      mockClient: MockClient((request) async {
        if (request.url.path == '/api/incident/reports') {
          expect(request.url.queryParameters['userRefId'], 'profile-test');
          return http.Response(
            jsonEncode({
              'items': [],
              'page': 1,
              'pageSize': 50,
              'totalPages': 0,
              'totalCount': 0,
            }),
            200,
          );
        }
        throw StateError('Petición inesperada: ${request.url.path}');
      }),
    );
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final token =
        '${encode({'alg': 'none'})}.${encode({'sub': 'profile-test', 'email': 'profile@uct.cl', 'role': 'Student', 'iss': 'https://identity-api', 'aud': 'api-gateway', 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test';
    await session.signInReal(
      AuthLoginResult(
        userId: 'profile-test',
        email: 'profile@uct.cl',
        token: token,
      ),
    );
  }

  Widget createWidgetUnderTest() {
    return const MaterialApp(home: Scaffold(body: ProfileScreen()));
  }

  testWidgets(
    'ProfileScreen muestra avatar y acciones reales sin inventar rol ni favoritos',
    (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // 1. Verificar lápiz de edición sobre el avatar
      expect(find.byIcon(Icons.edit), findsNothing);

      // 2. Sin sesión no hay rol asignado: no se muestra ningún pill de rol
      expect(find.text('Estudiante'), findsNothing);

      // 3. Verificar los 5 botones principales según el diseño Figma
      expect(find.text('Mis favoritos o guardados'), findsNothing);
      expect(find.text('Mis reportes'), findsOneWidget);
      expect(find.text('Objetos reportados'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);

      // 4. Verificar que muestra únicamente la cantidad numérica y no texto '¡1 Alerta!'
      expect(find.text('¡1 Alerta!'), findsNothing);
      expect(
        find.text('1'),
        findsNothing,
      ); // Sin fuente no se inventa un contador.
    },
  );

  testWidgets(
    'ProfileScreen sin notificaciones no muestra badge en Objetos reportados',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileScreen(notificationsCount: 0)),
        ),
      );

      expect(find.text('Objetos reportados'), findsOneWidget);
      expect(find.text('¡1 Alerta!'), findsNothing);
    },
  );

  testWidgets('Perfil no ofrece cambios de foto simulados', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.byIcon(Icons.edit), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsNothing);
    expect(find.text('Mis favoritos o guardados'), findsNothing);
  });

  testWidgets('Navegación a Mis reportes', (tester) async {
    await signIn();
    expect(session.isAuthenticated, isTrue);
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Mis reportes'));
    await tester.pumpAndSettle();

    expect(find.byType(MyReportsScreen), findsOneWidget);
    expect(find.text('Mis Reportes de Incidencias'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('Navegación a Objetos reportados con notificaciones', (
    tester,
  ) async {
    await signIn();
    expect(session.isAuthenticated, isTrue);
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Objetos reportados'));
    await tester.pumpAndSettle();

    expect(find.byType(MyLostItemsScreen), findsOneWidget);
    expect(find.text('Objetos reportados'), findsOneWidget);
    expect(
      find.text('No hay objetos reportados para este filtro.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('Navegación a Configuración', (tester) async {
    await signIn();
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.text('Configuración'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSettingsScreen), findsOneWidget);
    expect(find.text('Acceso y sesión'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
  });

  testWidgets('Botón Cerrar sesión abre diálogo de confirmación', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final logoutButton = find.text('Cerrar sesión');
    await tester.ensureVisible(logoutButton);
    await tester.pumpAndSettle();

    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        '¿Estás seguro de que deseas cerrar sesión? Deberás ingresar nuevamente con tu correo institucional @uct.cl.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancelar'), findsOneWidget);
  });
}
