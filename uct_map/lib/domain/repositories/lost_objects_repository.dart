import '../../data/models/lost_object_dto.dart';
import '../entities/lost_object.dart';

/// Contrato del repositorio de Objetos Perdidos (Incident Service / Lost Objects).
abstract class LostObjectsRepository {
  /// Registra un nuevo objeto perdido (POST /api/incident/lost-objects).
  ///
  /// Valida de antemano que [dto.photoUrl] sea una URL pública absoluta y que los campos
  /// requeridos cumplan las reglas de validación. Retorna el ID asignado en MongoDB.
  Future<CreateLostObjectResponse> createLostObject(CreateLostObjectDto dto);

  /// Consulta el listado paginado de objetos perdidos con soporte de filtros
  /// (title, structureId, status, sortBy, descending, page, pageSize).
  Future<PaginatedLostObjectsResponse> getLostObjects({
    LostObjectFilterParams? filter,
  });

  /// Actualiza el estado de un objeto perdido existente (PATCH /api/incident/lost-objects/{id}/lost/status).
  Future<void> updateStatus(String id, LostObjectStatus newStatus);
}
