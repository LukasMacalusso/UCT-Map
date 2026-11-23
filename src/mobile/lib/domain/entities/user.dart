import 'user_role.dart';

// Identidad local; los permisos conservan todos los roles del JWT.
class User {
  final String id;
  final String email;
  final String? name;
  final List<UserRole> roles;
  UserRole get role => roles.isEmpty ? UserRole.desconocido : roles.first;
  bool hasRole(UserRole role) => roles.contains(role);
  final DateTime registrationDate;

  const User({
    required this.id,
    required this.email,
    this.name,
    required this.roles,
    required this.registrationDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final roles = rawRoles is List
        ? rawRoles.map(UserRole.fromString).toList()
        : const <UserRole>[];
    return User(
      id: _str(json['userId']),
      email: _str(json['email']),
      name: _nonEmpty(json['name']),
      roles: List.unmodifiable(roles),
      registrationDate: _date(json['registrationDate']),
    );
  }

  /// Usuario recién logueado: trae UserId + Email (+ Name si el backend lo
  /// envía); el rol llega en el JWT y RegistrationDate cae al default.
  factory User.fromLogin({
    required String userId,
    required String email,
    String? name,
    UserRole role = UserRole.desconocido,
    List<UserRole>? roles,
  }) {
    return User(
      id: userId,
      email: email,
      name: _nonEmpty(name),
      roles: List.unmodifiable(roles ?? [role]),
      registrationDate: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          roles.length == other.roles.length &&
          roles.asMap().entries.every((e) => other.roles[e.key] == e.value) &&
          registrationDate == other.registrationDate;

  @override
  int get hashCode =>
      Object.hash(id, email, name, Object.hashAll(roles), registrationDate);
}

String _str(dynamic v) => v?.toString() ?? '';

String? _nonEmpty(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

DateTime _date(dynamic v) {
  if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
  return DateTime.now();
}
