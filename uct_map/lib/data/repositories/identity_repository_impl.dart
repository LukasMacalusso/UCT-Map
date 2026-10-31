import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/identity_repository.dart';

class IdentityRepositoryImpl implements IdentityRepository {
  IdentityRepositoryImpl({ApiClient? client})
    : _client = client ?? ApiClientProvider.apiClient;
  final ApiClient _client;
  @override
  Future<List<ManagedUser>> getUsers() async {
    final data = await _client.getJson<List<dynamic>>('/api/identity');
    return data
        .map((u) => ManagedUser.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> replaceRole(String userId, String role) async {
    await _client.put(
      '/api/identity/$userId/roles',
      body: {
        'roles': [role],
      },
    );
  }

  @override
  Future<void> setSuspended(String userId, bool suspended) async {
    final path = '/api/identity/$userId/suspension';
    if (suspended) {
      await _client.post(path);
    } else {
      await _client.delete(path);
    }
  }
}
