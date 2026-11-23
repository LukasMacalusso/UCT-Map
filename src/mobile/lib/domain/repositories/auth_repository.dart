// POST /api/identity/login {email, password} -> {userId, email, token}.
class AuthLoginResult {
  const AuthLoginResult({
    required this.userId,
    required this.email,
    required this.token,
  });

  final String userId;
  final String email;
  final String token;
}

/// Error de login con mensaje listo para mostrar en UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

abstract class AuthRepository {
  Future<AuthLoginResult> login({
    required String email,
    required String password,
  });
}

/// Inicio externo; null representa una cancelación sin crear sesión.
abstract class OAuthRepository {
  Future<AuthLoginResult?> signIn();
}
