import 'package:http/http.dart' as http;

import '../../core/network/api_client.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_endpoints.dart';

import '../../domain/entities/building.dart';
import '../../domain/entities/campus.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/structure.dart';
import '../../domain/repositories/campus_repository.dart';

import '../models/building_model.dart';
import '../models/campus_model.dart';
import '../models/category_model.dart';
import '../models/room_model.dart';
import '../models/structure_model.dart';
import '../models/campus_location_dto.dart';

/// Consumo centralizado de Campus Service mediante API Gateway.
/// Reutiliza ApiClient, la sesión JWT y el manejo de errores existente.
class CampusRemoteDataSource implements CampusRepository {
  CampusRemoteDataSource({http.Client? client, ApiConfig? config})
    : _api = client == null && config == null
          ? ApiClientProvider.apiClient
          : ApiClient(
              client: client ?? ApiClientProvider.defaultClient,
              config: config,
            );

  final ApiClient _api;

  Future<void> _discardResponse(Future<http.Response> request) async {
    await request;
  }

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _api.getJson<List<dynamic>>(
      path,
      queryParameters: query,
    );

    return data
        .map((value) => parse((value as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<T> _one<T>(String path, T Function(Map<String, dynamic>) parse) async {
    final data = await _api.getJson<Map<String, dynamic>>(path);
    return parse(data);
  }

  Map<String, dynamic>? _query(Map<String, String?> items) {
    final filtered = <String, dynamic>{};

    for (final entry in items.entries) {
      if (entry.value != null && entry.value!.trim().isNotEmpty) {
        filtered[entry.key] = entry.value;
      }
    }

    return filtered.isEmpty ? null : filtered;
  }

  // -------------------------------------------------------------
  // CAMPUS
  // -------------------------------------------------------------

  @override
  Future<List<Campus>> getCampuses() =>
      _list(ApiEndpoints.campusList, CampusModel.fromJson);

  @override
  Future<Campus> getCampusById(String id) =>
      _one(ApiEndpoints.campusDetail(id), CampusModel.fromJson);

  Future<Campus> createCampus(Map<String, Object?> payload) => _api.postJson(
    ApiEndpoints.campusList,
    body: payload,
    fromJson: (json) =>
        CampusModel.fromJson((json as Map).cast<String, dynamic>()),
  );

  Future<void> updateCampus(String id, Map<String, Object?> payload) =>
      _discardResponse(_api.put(ApiEndpoints.campusDetail(id), body: payload));

  Future<void> updateCampusLocation(
    String id,
    double latitude,
    double longitude,
  ) => _discardResponse(
    _api.patch(
      '${ApiEndpoints.campusDetail(id)}/location',
      body: {'latitude': latitude, 'longitude': longitude},
    ),
  );

  Future<void> deleteCampus(String id) =>
      _discardResponse(_api.delete(ApiEndpoints.campusDetail(id)));

  // -------------------------------------------------------------
  // BUILDINGS
  // -------------------------------------------------------------

  @override
  Future<List<Building>> getBuildings(String campusId) => _list(
    ApiEndpoints.campusBuildingsList,
    BuildingModel.fromJson,
    query: {'campusId': campusId},
  );

  @override
  Future<Building> getBuildingById(String id) =>
      _one(ApiEndpoints.buildingDetail(id), BuildingModel.fromJson);

  Future<Building> createBuilding(Map<String, Object?> payload) =>
      _api.postJson(
        ApiEndpoints.campusBuildingsList,
        body: payload,
        fromJson: (json) =>
            BuildingModel.fromJson((json as Map).cast<String, dynamic>()),
      );

  Future<void> updateBuilding(String id, Map<String, Object?> payload) =>
      _discardResponse(
        _api.put(ApiEndpoints.buildingDetail(id), body: payload),
      );

  Future<void> updateBuildingLocation(
    String id,
    double latitude,
    double longitude,
  ) => _discardResponse(
    _api.patch(
      '${ApiEndpoints.buildingDetail(id)}/location',
      body: {'latitude': latitude, 'longitude': longitude},
    ),
  );

  Future<void> deleteBuilding(String id) =>
      _discardResponse(_api.delete(ApiEndpoints.buildingDetail(id)));

  @override
  Future<List<BuildingLocationDto>> getBuildingLocations({String? campusId}) =>
      _list(
        ApiEndpoints.campusBuildingLocationsPath,
        BuildingLocationDto.fromJson,
        query: _query({'campusId': campusId}),
      );

  // -------------------------------------------------------------
  // ROOMS
  // -------------------------------------------------------------

  @override
  Future<List<Room>> getRooms(String buildingId) =>
      _list(ApiEndpoints.buildingRooms(buildingId), RoomModel.fromJson);

  @override
  Future<Room> getRoomById(String id) =>
      _one(ApiEndpoints.roomDetail(id), RoomModel.fromJson);

  Future<Room> createRoom(Map<String, Object?> payload) => _api.postJson(
    ApiEndpoints.campusRooms,
    body: payload,
    fromJson: (json) =>
        RoomModel.fromJson((json as Map).cast<String, dynamic>()),
  );

  Future<void> updateRoom(String id, Map<String, Object?> payload) =>
      _discardResponse(_api.put(ApiEndpoints.roomDetail(id), body: payload));

  Future<void> deleteRoom(String id) =>
      _discardResponse(_api.delete(ApiEndpoints.roomDetail(id)));

  @override
  Future<List<Room>> searchRooms(String term) => _list(
    ApiEndpoints.campusRoomSearchPath,
    RoomModel.fromJson,
    query: {'term': term},
  );

  @override
  Future<List<Room>> getRoomsFiltered({
    String? buildingId,
    String? categoryId,
  }) => _list(
    ApiEndpoints.campusRooms,
    RoomModel.fromJson,
    query: _query({'buildingId': buildingId, 'categoryId': categoryId}),
  );

  // -------------------------------------------------------------
  // STRUCTURES
  // -------------------------------------------------------------

  @override
  Future<List<Structure>> getStructures(String campusId) =>
      getStructuresFiltered(campusId: campusId);

  @override
  Future<List<Structure>> getStructuresFiltered({
    String? campusId,
    String? categoryId,
  }) => _list(
    ApiEndpoints.campusStructuresList,
    StructureModel.fromJson,
    query: _query({'campusId': campusId, 'categoryId': categoryId}),
  );

  @override
  Future<Structure> getStructureById(String id) =>
      _one(ApiEndpoints.structureDetail(id), StructureModel.fromJson);

  Future<Structure> createStructure(Map<String, Object?> payload) =>
      _api.postJson(
        ApiEndpoints.campusStructuresList,
        body: payload,
        fromJson: (json) =>
            StructureModel.fromJson((json as Map).cast<String, dynamic>()),
      );

  Future<void> updateStructure(String id, Map<String, Object?> payload) =>
      _discardResponse(
        _api.put(ApiEndpoints.structureDetail(id), body: payload),
      );

  Future<void> updateStructureLocation(
    String id,
    double latitude,
    double longitude,
  ) => _discardResponse(
    _api.patch(
      '${ApiEndpoints.structureDetail(id)}/location',
      body: {'latitude': latitude, 'longitude': longitude},
    ),
  );

  Future<void> deleteStructure(String id) =>
      _discardResponse(_api.delete(ApiEndpoints.structureDetail(id)));

  @override
  Future<List<StructureLocationDto>> getStructureLocations({
    String? campusId,
  }) => _list(
    ApiEndpoints.campusStructureLocationsPath,
    StructureLocationDto.fromJson,
    query: _query({'campusId': campusId}),
  );

  // -------------------------------------------------------------
  // CATEGORIES
  // -------------------------------------------------------------

  @override
  Future<List<Category>> getCategories() =>
      _list(ApiEndpoints.campusCategories, CategoryModel.fromJson);

  @override
  Future<Category> getCategoryById(String id) =>
      _one(ApiEndpoints.categoryDetail(id), CategoryModel.fromJson);

  Future<Category> createCategory(Map<String, Object?> payload) =>
      _api.postJson(
        ApiEndpoints.campusCategories,
        body: payload,
        fromJson: (json) =>
            CategoryModel.fromJson((json as Map).cast<String, dynamic>()),
      );

  Future<void> updateCategory(String id, Map<String, Object?> payload) =>
      _discardResponse(
        _api.put(ApiEndpoints.categoryDetail(id), body: payload),
      );

  Future<void> reorderCategories(List<Map<String, Object?>> payload) =>
      _discardResponse(
        _api.put('${ApiEndpoints.campusCategories}/reorder', body: payload),
      );

  Future<void> deleteCategory(String id) =>
      _discardResponse(_api.delete(ApiEndpoints.categoryDetail(id)));
}
