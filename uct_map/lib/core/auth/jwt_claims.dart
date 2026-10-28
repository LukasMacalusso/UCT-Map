import 'dart:convert';

import '../../domain/entities/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

// Lee expiración, roles y emisor del JWT sin dependencias externas.
class JwtClaims {
  const JwtClaims({
    required this.subject,
    required this.email,
    required this.expiresAt,
    required this.roles,
    required this.issuer,
    required this.audience,
  });

  final String subject;
  final String email;
  final DateTime expiresAt;
  final List<UserRole> roles;
  final String issuer;
  final String audience;
}

/// Lee el token y, si se indican, exige que venga del emisor y para la
/// audiencia configurados en el entorno.
JwtClaims parseJwt(
  String token, {
  String? expectedIssuer,
  String? expectedAudience,
}) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) throw const FormatException('segmentos');
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('payload');
    }
    final sub = payload['sub'];
    final mail = payload['email'];
    final exp = payload['exp'];
    if (sub is! String || sub.isEmpty) throw const FormatException('sub');
    if (mail is! String || mail.isEmpty) throw const FormatException('email');
    if (exp is! num) throw const FormatException('exp');
    // El rol viaja como string único o lista. Identity lo emite en la
    // claim corta `role` o en la URI .NET estándar.
    final rawRoles = payload['role'] ??
        payload[
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
    final roles = switch (rawRoles) {
      final String s => [UserRole.fromString(s)],
      final List l => l.map(UserRole.fromString).toList(),
      _ => const <UserRole>[],
    };
    final issuer = payload['iss']?.toString() ?? '';
    final rawAudience = payload['aud'];
    final audience = payload['aud'] is List
        ? (payload['aud'] as List).map((a) => a.toString()).join(' ')
        : payload['aud']?.toString() ?? '';
    if (expectedIssuer != null && issuer != expectedIssuer) {
      throw const FormatException('iss');
    }
    if (expectedAudience != null &&
        !(rawAudience is List
            ? rawAudience.contains(expectedAudience)
            : rawAudience == expectedAudience)) {
      throw const FormatException('aud');
    }
    return JwtClaims(
      subject: sub,
      email: mail,
      expiresAt:
          DateTime.fromMillisecondsSinceEpoch((exp * 1000).toInt(), isUtc: true),
      roles: roles,
      issuer: issuer,
      audience: audience,
    );
  } on FormatException {
    throw const AuthFailure('Respuesta inesperada del servidor. Intenta de nuevo.');
  }
}
