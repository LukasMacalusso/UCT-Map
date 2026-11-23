import '../../domain/entities/managed_user.dart';

List<ManagedUser> filterUsers(
  Iterable<ManagedUser> users, {
  String query = '',
  String? role,
  bool? suspended,
}) {
  final term = query.trim().toLowerCase();
  return users
      .where(
        (u) =>
            (term.isEmpty ||
                u.name.toLowerCase().contains(term) ||
                u.email.toLowerCase().contains(term)) &&
            (role == null || u.role == role) &&
            (suspended == null || u.isSuspended == suspended),
      )
      .toList();
}
