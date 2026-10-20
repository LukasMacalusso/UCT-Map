import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/auth/jwt_claims.dart';
import '../../core/config/env_config.dart';
import '../../data/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

// Sesión en memoria con forma del backend y token persistido.
class SessionController extends ChangeNotifier {
  SessionController({TokenStorage? storage})
    : _storage = storage ?? SecureTokenStorage();

  final TokenStorage _storage;
  AuthSession? _session;
  Timer? _expiryTimer;

  /// Sube con cada cambio de sesión: una restauración en vuelo no debe
  /// recuperar una sesión que el usuario ya cerró.
  int _generation = 0;

  Future<void>? _ready;
  Future<void> _storageOperation = Future.value();

  // El borrado de una sesión anterior no debe adelantarse al nuevo guardado.
  Future<T> _withStorage<T>(Future<T> Function() operation) {
    final result = _storageOperation.then((_) => operation());
    _storageOperation = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  bool get isAuthenticated => _session != null && _session!.isValid;
  User? get currentUser => _session?.user;
  String? get token {
    final session = _session;
    final value = session?.token;
    if (session == null || !session.isValid) return null;
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> signInReal(AuthLoginResult result) async {
    final claims = parseJwt(
      result.token,
      expectedIssuer: EnvConfig.jwtIssuer,
      expectedAudience: EnvConfig.jwtAudience,
    );
    if (!claims.expiresAt.isAfter(DateTime.now()) ||
        claims.subject != result.userId ||
        claims.email != result.email) {
      throw const AuthFailure('La sesión recibida no es válida.');
    }
    final generation = ++_generation;
    return _withStorage(() async {
      await _storage.save(result.token);
      if (generation != _generation) {
        throw const AuthFailure('El inicio de sesión fue cancelado.');
      }
      _session = AuthSession(
        user: User.fromLogin(
          userId: result.userId,
          email: result.email,
          role: claims.roles.isNotEmpty
              ? claims.roles.first
              : UserRole.desconocido,
        ),
        loginAt: DateTime.now(),
        token: result.token,
        expiresAt: claims.expiresAt,
      );
      _scheduleExpiry(claims.expiresAt);
      notifyListeners();
    });
  }

  /// Termina cuando la restauración inicial terminó. Las pantallas que piden
  /// datos esperan esta futura para no pedir el token antes de conocerlo.
  Future<void> get ready => _ready ??= _restoreQuietly();

  Future<void> _restoreQuietly() async {
    try {
      await restore();
    } catch (_) {
      // Sin almacenamiento disponible se sigue sin sesión.
    }
  }

  Future<bool> restore() async {
    final generation = _generation;
    return _withStorage(() async {
      final token = await _storage.read();
      if (generation != _generation || token == null || token.isEmpty) {
        return false;
      }
      try {
        final claims = parseJwt(
          token,
          expectedIssuer: EnvConfig.jwtIssuer,
          expectedAudience: EnvConfig.jwtAudience,
        );
        if (!claims.expiresAt.isAfter(DateTime.now())) {
          await _storage.clear();
          return false;
        }
        _session = AuthSession(
          user: User.fromLogin(
            userId: claims.subject,
            email: claims.email,
            role: claims.roles.isNotEmpty
                ? claims.roles.first
                : UserRole.desconocido,
          ),
          loginAt: DateTime.now(),
          token: token,
          expiresAt: claims.expiresAt,
        );
        _scheduleExpiry(claims.expiresAt);
        notifyListeners();
        return true;
      } on AuthFailure {
        await _storage.clear();
        return false;
      }
    });
  }

  Future<void> signOut() async {
    _generation++;
    _expiryTimer?.cancel();
    _session = null;
    notifyListeners();
    await _withStorage(_storage.clear);
  }

  /// Cierra la sesión solo si el rechazo corresponde al token vigente:
  /// una respuesta atrasada de una petición anterior no debe expulsar a
  /// un usuario que acaba de iniciar sesión.
  void handleUnauthorized(String? usedToken) {
    if (usedToken == null || usedToken != _session?.token) return;
    unawaited(signOut().catchError((Object _) {}));
  }

  void _scheduleExpiry(DateTime expiresAt) {
    _expiryTimer?.cancel();
    _expiryTimer = Timer(expiresAt.difference(DateTime.now()), () {
      unawaited(signOut().catchError((Object _) {}));
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
