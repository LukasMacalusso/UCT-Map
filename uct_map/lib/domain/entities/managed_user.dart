/// Datos públicos de Identity para administración local de usuarios.
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isSuspended,
  });
  final String id;
  final String name;
  final String email;
  final String role;
  final bool isSuspended;
  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
    id: json['userId'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    isSuspended: json['isSuspended'] as bool? ?? false,
  );
}
