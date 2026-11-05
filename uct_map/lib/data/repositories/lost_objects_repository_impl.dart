import '../../domain/entities/lost_object.dart';
import '../../domain/repositories/lost_objects_repository.dart';
import '../datasources/lost_objects_remote_ds.dart';
import '../models/lost_object_dto.dart';

/// Implementación del repositorio de Objetos Perdidos según Arquitectura Limpia.
class LostObjectsRepositoryImpl implements LostObjectsRepository {
  @override
  Future<void> deleteLostObject(String id) =>
      _remoteDataSource.deleteLostObject(id);

  final LostObjectsRemoteDataSource _remoteDataSource;

  LostObjectsRepositoryImpl({LostObjectsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? LostObjectsRemoteDataSource();

  @override
  Future<LostObject> getLostObjectById(String id) =>
      _remoteDataSource.getLostObjectById(id);

  @override
  Future<CreateLostObjectResponse> createLostObject(CreateLostObjectDto dto) {
    return _remoteDataSource.createLostObject(dto);
  }

  @override
  Future<PaginatedLostObjectsResponse> getLostObjects({
    LostObjectFilterParams? filter,
  }) {
    return _remoteDataSource.getLostObjects(filter: filter);
  }

  @override
  Future<void> updateStatus(String id, LostObjectStatus newStatus) {
    return _remoteDataSource.updateStatus(id, newStatus);
  }
}
