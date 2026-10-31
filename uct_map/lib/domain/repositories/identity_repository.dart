import '../entities/managed_user.dart';

abstract class IdentityRepository {
  Future<List<ManagedUser>> getUsers();
  Future<void> replaceRole(String userId, String role);
  Future<void> setSuspended(String userId, bool suspended);
}
