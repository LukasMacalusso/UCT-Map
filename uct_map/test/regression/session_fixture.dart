import 'package:uct_map/core/config/env_config.dart';

import 'dart:convert';

import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';

class MemoryStorage implements TokenStorage {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> save(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

Future<SessionController> signIn(String role) async {
  final session = SessionController(storage: MemoryStorage());
  try {
    await account(session, 'user', role);
    return session;
  } catch (_) {
    session.dispose();
    rethrow;
  }
}

Future<void> account(SessionController session, String id, String role) async {
  await session.ready;
  final payload = {
    'sub': id,
    'email': '$id@uct.cl',
    'role': role,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
    'iss': EnvConfig.jwtIssuer,
    'aud': EnvConfig.jwtAudience,
  };
  final token =
      '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.${base64Url.encode(utf8.encode(jsonEncode(payload)))}.signature';
  await session.signInReal(
    AuthLoginResult(userId: id, email: '$id@uct.cl', token: token),
  );
}
