import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/config/env_config.dart';
import 'package:uct_map/core/network/api_config.dart';
import 'package:uct_map/core/network/authenticated_client.dart';
import 'package:uct_map/data/datasources/auth_remote_ds.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/entities/user_role.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';

import 'session_fixture.dart' as roles;
import 'session_fixture.dart' show MemoryStorage;

String jwt({int? expires, String? issuer, String? audience}) {
  String b64(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64({'sub': 'user', 'email': 'user@uct.cl', 'role': 'Student', 'exp': expires ?? DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1800, 'iss': issuer ?? EnvConfig.jwtIssuer, 'aud': audience ?? EnvConfig.jwtAudience})}.signature';
}

AuthLoginResult result(String token) =>
    AuthLoginResult(userId: 'user', email: 'user@uct.cl', token: token);

class DelayedStorage implements TokenStorage {
  final saveStarted = Completer<void>();
  final allowSave = Completer<void>();
  String? value;
  @override
  Future<void> save(String token) async {
    saveStarted.complete();
    await allowSave.future;
    value = token;
  }

  @override
  Future<String?> read() async => value;
  @override
  Future<void> clear() async {
    value = null;
  }
}

class FailingStorage extends MemoryStorage {
  bool failRead = false;
  bool failSave = false;
  bool failClear = false;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read failed');
    return super.read();
  }

  @override
  Future<void> save(String token) async {
    if (failSave) throw StateError('write failed');
    await super.save(token);
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('delete failed');
    await super.clear();
  }
}

void main() {
  group('Persistencia y expiración', () {
    test('un fallo de lectura permite iniciar como invitado', () async {
      final session = SessionController(
        storage: FailingStorage()..failRead = true,
      );
      addTearDown(session.dispose);
      await session.ready;
      expect(session.isAuthenticated, isFalse);
      expect(session.token, isNull);
    });

    test('un fallo de guardado no activa una sesión nueva', () async {
      final storage = FailingStorage();
      final session = SessionController(storage: storage);
      addTearDown(session.dispose);
      await session.ready;
      final current = jwt();
      await session.signInReal(result(current));
      storage.failSave = true;
      final next = jwt(
        expires: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 600,
      );
      await expectLater(session.signInReal(result(next)), throwsStateError);
      expect(session.token, current);
      expect(storage.token, current);
    });

    test(
      'si falla borrar, invalidar el valor evita que vuelva tras reiniciar',
      () async {
        final storage = FailingStorage();
        final session = SessionController(storage: storage);
        addTearDown(session.dispose);
        await session.ready;
        await session.signInReal(result(jwt()));
        storage.failClear = true;
        final logout = session.signOut();
        expect(session.isAuthenticated, isFalse);
        await logout;
        final restarted = SessionController(storage: storage);
        addTearDown(restarted.dispose);
        await restarted.ready;
        expect(restarted.isAuthenticated, isFalse);
        expect(restarted.token, isNull);
      },
    );

    test('si fallan ambos métodos, informa el fallo y bloquea restaurar en memoria', () async {
      final storage = FailingStorage();
      final session = SessionController(storage: storage);
      addTearDown(session.dispose);
      await session.ready;
      await session.signInReal(result(jwt()));
      storage
        ..failClear = true
        ..failSave = true;
      await expectLater(session.signOut(), throwsStateError);
      expect(await session.restore(), isFalse);
      expect(session.token, isNull);
    });

    test(
      'persistencia, restauración y cierre de sesión mantienen una sola cuenta',
      () async {
        final storage = MemoryStorage();
        final session = SessionController(storage: storage);
        await session.ready;
        await session.signInReal(result(jwt()));
        expect(storage.token, session.token);
        session.dispose();
        final restored = SessionController(storage: storage);
        await restored.ready;
        expect(restored.currentUser?.role, UserRole.estudiante);
        await restored.signOut();
        expect(storage.token, isNull);
        expect(restored.isAuthenticated, isFalse);
        restored.dispose();
      },
    );
    test(
      'claims inválidos o expirados no crean ni restauran una sesión',
      () async {
        final storage = MemoryStorage();
        final session = SessionController(storage: storage);
        await session.ready;
        for (final token in [
          jwt(issuer: 'otro'),
          jwt(audience: 'otra'),
          jwt(expires: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1),
        ]) {
          await expectLater(
            session.signInReal(result(token)),
            throwsA(isA<AuthFailure>()),
          );
          expect(session.isAuthenticated, isFalse);
        }
        session.dispose();
        storage.token = jwt(
          expires: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 1,
        );
        final restored = SessionController(storage: storage);
        await restored.ready;
        expect(restored.isAuthenticated, isFalse);
        expect(storage.token, isNull);
        restored.dispose();
      },
    );
    testWidgets('el vencimiento elimina la sesión y el token guardado', (
      tester,
    ) async {
      final storage = MemoryStorage();
      final session = SessionController(storage: storage);
      await session.ready;
      await session.signInReal(
        result(jwt(expires: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1)),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(session.isAuthenticated, isFalse);
      expect(storage.token, isNull);
      session.dispose();
    });
    test(
      'cierre durante guardado serializa el borrado y no restaura la sesión',
      () async {
        final storage = DelayedStorage();
        final session = SessionController(storage: storage);
        await session.ready;
        final pending = session.signInReal(result(jwt()));
        final canceled = expectLater(pending, throwsA(isA<AuthFailure>()));
        await storage.saveStarted.future;
        final logout = session.signOut();
        storage.allowSave.complete();
        await canceled;
        await logout;
        expect(storage.value, isNull);
        expect(session.isAuthenticated, isFalse);
        session.dispose();
      },
    );
  });

  group('Autorización HTTP', () {
    for (final (label, role, status, authorization, keepsSession) in [
      ('403 conserva la sesión vigente', 'Student', 403, null, true),
      (
        '401 de un Bearer explícito anterior conserva la sesión',
        'Teacher',
        401,
        'Bearer old-account-token',
        true,
      ),
      ('401 del Bearer vigente cierra la sesión', 'Student', 401, null, false),
      (
        '401 de otro esquema conserva la sesión',
        'Teacher',
        401,
        'Basic other-credentials',
        true,
      ),
    ]) {
      test(label, () async {
        final session = await roles.signIn(role);
        addTearDown(session.dispose);
        final client = AuthenticatedClient(
          innerClient: MockClient((_) async => http.Response('', status)),
          tokenProvider: () => session.token,
          onUnauthorized: session.handleUnauthorized,
          enableLogging: false,
        );
        addTearDown(client.close);

        final response = await client.get(
          Uri.parse('https://gateway.invalid/test-resource'),
          headers: authorization == null
              ? null
              : {'Authorization': authorization},
        );

        expect(response.statusCode, status);
        expect(session.isAuthenticated, keepsSession);
      });
    }

    test('un login rechazado no envía ni cierra la sesión existente', () async {
      final session = await roles.signIn('Student');
      String? authorization;
      final client = AuthenticatedClient(
        innerClient: MockClient((request) async {
          authorization = request.headers['authorization'];
          return http.Response('', 401);
        }),
        tokenProvider: () => session.token,
        onUnauthorized: session.handleUnauthorized,
        enableLogging: false,
      );
      final auth = AuthRemoteDataSource(
        client: client,
        config: ApiConfig(baseUrl: 'https://gateway.invalid'),
      );
      await expectLater(
        auth.login(email: 'user@uct.cl', password: 'incorrecta'),
        throwsA(isA<AuthFailure>()),
      );
      expect(authorization, isNull);
      expect(session.isAuthenticated, isTrue);
      client.close();
      session.dispose();
    });
    test('401 tardío de Bearer inyectado no cierra la nueva cuenta', () async {
      final session = await roles.signIn('Student');
      final teacher = await roles.signIn('Teacher');
      final teacherToken = teacher.token!;
      teacher.dispose();
      final pending = Completer<http.Response>();
      final started = Completer<void>();
      final client = AuthenticatedClient(
        innerClient: MockClient((_) {
          started.complete();
          return pending.future;
        }),
        tokenProvider: () => session.token,
        onUnauthorized: session.handleUnauthorized,
        enableLogging: false,
      );
      final request = client.get(
        Uri.parse('https://gateway.invalid/test-resource'),
      );
      await started.future;
      await session.signInReal(
        AuthLoginResult(
          userId: 'user',
          email: 'user@uct.cl',
          token: teacherToken,
        ),
      );
      pending.complete(http.Response('', 401));
      await request;
      expect(session.currentUser?.role, UserRole.profesor);
      expect(session.isAuthenticated, isTrue);
      client.close();
      session.dispose();
    });
  });
}
