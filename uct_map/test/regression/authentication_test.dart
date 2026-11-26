import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_config.dart';
import 'package:uct_map/data/datasources/auth_remote_ds.dart';
import 'package:uct_map/domain/entities/app_permission.dart';
import 'package:uct_map/domain/entities/user_role.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/presentation/screens/login/login_page.dart';
import 'package:uct_map/presentation/screens/login/session_required_view.dart';

import 'session_fixture.dart' as roles;
import 'test_fonts.dart' show loadUiFonts;

class FakeAuth implements AuthRepository {
  FakeAuth(this.response);
  final Future<AuthLoginResult> response;
  @override
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) => response;
}

Future<void> startLogin(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('authGateLoginButton')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'user@uct.cl');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  await tester.ensureVisible(
    find.widgetWithText(ElevatedButton, 'Iniciar Sesión'),
  );
  await tester.tap(find.widgetWithText(ElevatedButton, 'Iniciar Sesión'));
  await tester.pump();
}

class FailingAuth implements AuthRepository {
  @override
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  }) async => throw const AuthFailure('Correo o contraseña inválidos.');
}

void main() {
  group('Inicio y retorno', () {
    for (final role in ['ComplaintsOfficer', 'Student']) {
      testWidgets('login $role conserva ruta protegida y respeta permiso', (
        tester,
      ) async {
        final session = SessionController(storage: roles.MemoryStorage());
        await session.ready;
        final source = await roles.signIn(role);
        final token = source.token!;
        source.dispose();
        ApiClientProvider.initialize(session);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionRequiredView(
                permission: AppPermission.manageReports,
                builder: (_) => const Text('Gestión protegida'),
              ),
            ),
            routes: {
              '/login': (_) => LoginPage(
                authRepository: FakeAuth(
                  Future.value(
                    AuthLoginResult(
                      userId: 'user',
                      email: 'user@uct.cl',
                      token: token,
                    ),
                  ),
                ),
              ),
            },
          ),
        );
        await tester.pumpAndSettle();
        await startLogin(tester);
        await tester.pumpAndSettle();
        if (role == 'ComplaintsOfficer') {
          expect(find.text('Gestión protegida'), findsOneWidget);
        } else {
          expect(find.text('Gestión protegida'), findsNothing);
          expect(
            find.text('Tu rol no tiene acceso a esta sección.'),
            findsOneWidget,
          );
        }
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      });
    }
    testWidgets(
      'cancelar login durante carga vuelve a la ruta sin iniciar sesión',
      (tester) async {
        final session = SessionController(storage: roles.MemoryStorage());
        await session.ready;
        final source = await roles.signIn('Student');
        final token = source.token!;
        source.dispose();
        final pending = Completer<AuthLoginResult>();
        ApiClientProvider.initialize(session);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionRequiredView(
                builder: (_) => const Text('Contenido protegido'),
              ),
            ),
            routes: {
              '/login': (_) =>
                  LoginPage(authRepository: FakeAuth(pending.future)),
            },
          ),
        );
        await tester.pumpAndSettle();
        await startLogin(tester);
        await tester.ensureVisible(find.byTooltip('Volver'));
        await tester.tap(find.byTooltip('Volver'));
        await tester.pumpAndSettle();
        pending.complete(
          AuthLoginResult(userId: 'user', email: 'user@uct.cl', token: token),
        );
        await tester.pumpAndSettle();
        expect(session.isAuthenticated, isFalse);
        expect(
          find.byKey(const ValueKey('authGateLoginButton')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
  });

  group('Errores de inicio', () {
    for (final testCase in [
      (400, '{}', 'Faltan el correo o la contraseña.'),
      (401, '{}', 'Correo o contraseña inválidos.'),
      (503, '{}', 'Error del servidor (503). Intenta de nuevo.'),
      (200, 'no-json', 'Respuesta inesperada del servidor. Intenta de nuevo.'),
      (
        200,
        '{"userId":"u"}',
        'Respuesta inesperada del servidor. Intenta de nuevo.',
      ),
    ]) {
      test(
        'login distingue HTTP ${testCase.$1} y errores de formato',
        () async {
          final repo = AuthRemoteDataSource(
            client: MockClient(
              (_) async => http.Response(testCase.$2, testCase.$1),
            ),
            config: ApiConfig(baseUrl: 'https://gateway.invalid'),
          );
          await expectLater(
            repo.login(email: 'test@uct.cl', password: 'password'),
            throwsA(
              isA<AuthFailure>().having(
                (e) => e.message,
                'message',
                testCase.$3,
              ),
            ),
          );
        },
      );
    }
    test('sin conexión no se informa como credenciales incorrectas', () async {
      final repo = AuthRemoteDataSource(
        client: MockClient((_) async => throw http.ClientException('offline')),
        config: ApiConfig(baseUrl: 'https://gateway.invalid'),
      );
      await expectLater(
        repo.login(email: 'test@uct.cl', password: 'password'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            contains('Sin conexión'),
          ),
        ),
      );
    });
    test('timeout se comunica sin inventar éxito', () async {
      final pending = Completer<http.Response>();
      final repo = AuthRemoteDataSource(
        client: MockClient((_) => pending.future),
        config: ApiConfig(
          baseUrl: 'https://gateway.invalid',
          timeout: const Duration(milliseconds: 20),
        ),
      );
      await expectLater(
        repo.login(email: 'test@uct.cl', password: 'password'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            contains('no responde'),
          ),
        ),
      );
    });
  });

  group('Carreras de inicio', () {
    for (final change in ['otra cuenta', 'cierre']) {
      testWidgets('descarta login pendiente tras $change', (tester) async {
        final session = SessionController(storage: roles.MemoryStorage());
        await session.ready;
        final oldAccount = await roles.signIn('Student');
        final newAccount = await roles.signIn('Teacher');
        final oldToken = oldAccount.token!;
        final newToken = newAccount.token!;
        ApiClientProvider.initialize(session);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SessionRequiredView(
                builder: (_) => const Text('Contenido'),
              ),
            ),
            routes: {
              '/login': (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.pop(context, {
                    'ok': true,
                    'userId': 'user',
                    'email': 'user@uct.cl',
                    'token': oldToken,
                  }),
                  child: const Text('Completar login'),
                ),
              ),
            },
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('authGateLoginButton')));
        await tester.pumpAndSettle();
        if (change == 'otra cuenta') {
          await session.signInReal(
            AuthLoginResult(
              userId: 'user',
              email: 'user@uct.cl',
              token: newToken,
            ),
          );
        } else {
          await session.signOut();
        }
        await tester.pumpAndSettle();
        await tester.tap(find.text('Completar login'));
        await tester.pumpAndSettle();
        if (change == 'otra cuenta') {
          expect(session.currentUser?.role, UserRole.profesor);
        } else {
          expect(session.isAuthenticated, isFalse);
        }
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
        oldAccount.dispose();
        newAccount.dispose();
      });
    }
  });

  group('Accesibilidad de inicio', () {
    setUpAll(loadUiFonts);

    for (final scale in [1.0, 2.0]) {
      testWidgets('formulario con error, texto al ${scale * 100} %', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(390, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        const captureKey = ValueKey('capture');
        await tester.pumpWidget(
          RepaintBoundary(
            key: captureKey,
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              initialRoute: '/login',
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => settings.name == '/login'
                    ? LoginPage(authRepository: FailingAuth())
                    : const Scaffold(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'test@uct.cl');
        await tester.enterText(find.byType(TextFormField).last, 'invalid');
        final submit = find.widgetWithText(ElevatedButton, 'Iniciar Sesión');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(find.text('Correo o contraseña inválidos.'), findsOneWidget);
        await tester.ensureVisible(find.text('Volver'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
