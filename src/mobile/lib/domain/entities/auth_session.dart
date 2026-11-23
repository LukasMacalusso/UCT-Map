import 'user.dart';

/// Modelo de sesión de usuario autenticado con token JWT.
class AuthSession {
  final User user;
  final DateTime loginAt;
  final String? token;
  final DateTime? expiresAt;

  const AuthSession({
    required this.user,
    required this.loginAt,
    this.token,
    this.expiresAt,
  });

  bool get isValid {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }
    return true;
  }
}
