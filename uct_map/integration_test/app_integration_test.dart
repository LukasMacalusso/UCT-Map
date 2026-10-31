import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uct_map/core/config/env_config.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/main.dart';
import 'package:uct_map/presentation/navigation/main_navigation_screen.dart';
import 'package:uct_map/presentation/screens/login/auth_required_view.dart';
import 'package:uct_map/presentation/screens/login/session_required_view.dart';
import 'package:uct_map/presentation/screens/login/login_page.dart';
import 'package:uct_map/presentation/screens/profile/profile_screen.dart';
import 'package:uct_map/presentation/widgets/custom_drawer.dart';
import 'package:uct_map/presentation/widgets/uct_logo.dart';
import '../test/helpers/mock_mapbox_platform.dart';

class _MockAuthRepo implements AuthRepository {
  @override
  Future<AuthLoginResult> login(
      {required String email, required String password}) async {
    return AuthLoginResult(
      userId: 'u-integration-test',
      email: email,
      token: generateJwt(email),
    );
  }

  static String generateJwt(String email, {String userId = 'u-test'}) {
    String b64(Object o) => base64Encode(utf8.encode(jsonEncode(o)))
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
    final exp =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;
    return "${b64({'alg': 'none'})}.${b64({'sub': userId, 'email': email, 'role': 'estudiante', 'exp': exp, 'iss': EnvConfig.jwtIssuer, 'aud': EnvConfig.jwtAudience})}.x";
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupMockMapboxPlatform();
  });

  group('UCT Map Mobile Integration Tests', () {
    testWidgets('Flujo 1: Inicio de app y navegacion completa entre tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(UctMapApp(authRepository: _MockAuthRepo()));
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(find.text('Mapa del Campus'), findsOneWidget);

      // Verificar existencia de los 5 destinos de navegacion
      expect(find.text('Mapa'), findsOneWidget);
      expect(find.text('Buscar'), findsOneWidget);
      expect(find.text('Objetos'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      // Navegar a Buscar
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      expect(find.text('Búsqueda'), findsOneWidget);

      // Navegar a Objetos (requiere sesion)
      await tester.tap(find.text('Objetos'));
      await tester.pumpAndSettle();
      expect(find.text('Objetos Perdidos'), findsOneWidget);
      expect(find.byType(SessionRequiredView), findsOneWidget);

      // Navegar a Reportes (requiere sesion)
      await tester.tap(find.text('Reportes'));
      await tester.pumpAndSettle();
      expect(find.text('Reportes de Incidencias'), findsOneWidget);
      expect(find.byType(SessionRequiredView), findsOneWidget);

      // Navegar a Perfil
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Mi Perfil'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Retornar a Mapa
      await tester.tap(find.text('Mapa'));
      await tester.pumpAndSettle();
      expect(find.text('Mapa del Campus'), findsOneWidget);
    });

    testWidgets('Flujo 2: Menu lateral CustomDrawer e interaccion institucional',
        (WidgetTester tester) async {
      await tester.pumpWidget(UctMapApp(authRepository: _MockAuthRepo()));
      await tester.pumpAndSettle();

      // Abrir el Drawer mediante el logo institucional
      final logoFinder = find.byType(UctLogo).first;
      expect(logoFinder, findsOneWidget);
      await tester.tap(logoFinder);
      await tester.pumpAndSettle();

      // Validar que el Drawer se despliega correctamente
      expect(find.byType(CustomDrawer), findsOneWidget);
      expect(find.text('UCT Map'), findsOneWidget);
      expect(find.text('Universidad Católica de Temuco'), findsOneWidget);
      expect(find.text('Inicio y Accesos Rápidos'), findsOneWidget);

      // Cerrar Drawer pulsando fuera o deslizando
      final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.closeDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(CustomDrawer), findsNothing);
    });

    testWidgets('Flujo 3: Proteccion de sesion, navegacion a Login y autenticacion',
        (WidgetTester tester) async {
      await tester.pumpWidget(UctMapApp(authRepository: _MockAuthRepo()));
      await tester.pumpAndSettle();

      // Navegar a Reportes sin sesion
      await tester.tap(find.text('Reportes'));
      await tester.pumpAndSettle();

      expect(find.byType(SessionRequiredView), findsOneWidget);
      final loginBtn = find.byKey(const ValueKey('authGateLoginButton'));
      expect(loginBtn, findsOneWidget);

      // Pulsar Iniciar sesion y validar transicion a LoginPage
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Inicia Sesión'), findsOneWidget);

      // Regresar a la pantalla anterior
      final backBtn = find.byTooltip('Volver');
      if (backBtn.evaluate().isNotEmpty) {
        await tester.tap(backBtn);
        await tester.pumpAndSettle();
      }

      // Autenticar la sesion directamente
      final mockSession = ApiClientProvider.session;
      const testEmail = 'estudiante@alu.uct.cl';
      const testUserId = 'u-e2e';
      await mockSession.signInReal(
        AuthLoginResult(
          userId: testUserId,
          email: testEmail,
          token: _MockAuthRepo.generateJwt(testEmail, userId: testUserId),
        ),
      );
      await tester.pumpAndSettle();

      // Con sesion activa, ya no debe mostrar AuthRequiredView bloqueante
      expect(find.byType(AuthRequiredView), findsNothing);

      // Cerrar sesion y limpiar estado
      await mockSession.signOut();
      await tester.pumpAndSettle();
    });
  });
}
