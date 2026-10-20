import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/auth/jwt_claims.dart';
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
    final claims = parseJwt(result.token);
    if (!claims.expiresAt.isAfter(DateTime.now()) ||
        claims.subject != result.userId ||
        claims.email != result.email) {
      throw const AuthFailure('La sesión recibida no es válida.');
    }
    await _storage.save(result.token);
    _session = AuthSession(
      user: User.fromLogin(
        userId: result.userId,
        email: result.email,
        role: claims.roles.isNotEmpty ? claims.roles.first : UserRole.desconocido,
      ),
      loginAt: DateTime.now(),
      token: result.token,
      expiresAt: claims.expiresAt,
    );
    _scheduleExpiry(claims.expiresAt);
    notifyListeners();
  }

  Future<bool> restore() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) return false;
    try {
      final claims = parseJwt(token);
      if (!claims.expiresAt.isAfter(DateTime.now())) {
        await _storage.clear();
        return false;
      }
      _session = AuthSession(
        user: User.fromLogin(
          userId: claims.subject,
          email: claims.email,
          role: claims.roles.isNotEmpty ? claims.roles.first : UserRole.desconocido,
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
    _expiryTimer?.cancel();
    _session = null;
    notifyListeners();
    await _storage.clear();
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
