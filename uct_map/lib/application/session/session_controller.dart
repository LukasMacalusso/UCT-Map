import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/auth/jwt_claims.dart';
import '../../core/config/env_config.dart';
import '../../data/storage/token_storage.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user.dart';
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
        claims.subject != result.userId || claims.email != result.email) {
      throw const AuthFailure('La sesión recibida no es válida.');
    }
    await _storage.save(result.token);
    _generation++;
    _session = AuthSession(
      user: User.fromLogin(
        userId: result.userId,
        email: result.email,
        roles: claims.roles,
      ),
      loginAt: DateTime.now(),
      token: result.token,
      expiresAt: claims.expiresAt,
    );
    _scheduleExpiry(claims.expiresAt);
    notifyListeners();
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
    final token = await _storage.read();
    if (token == null || token.isEmpty) return false;
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
      if (generation != _generation) return false;
      _session = AuthSession(
        user: User.fromLogin(
          userId: claims.subject,
          email: claims.email,
          roles: claims.roles,
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
  }

  Future<void> signOut() async {
    _generation++;
    _expiryTimer?.cancel();
    _session = null;
    notifyListeners();
    await _storage.clear();
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
