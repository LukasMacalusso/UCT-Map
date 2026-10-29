import '../../data/models/campus_location_dto.dart';
import '../entities/building.dart';
import '../entities/campus.dart';
import '../entities/category.dart';
import '../entities/room.dart';
import '../entities/structure.dart';

/// Contrato del repositorio para consumir el Campus Service.
abstract class CampusRepository {
  Future<List<Campus>> getCampuses();

  Future<List<Building>> getBuildings(String campusId);

  Future<List<Room>> getRooms(String buildingId);

  Future<List<Structure>> getStructures(String campusId);

  Future<List<Category>> getCategories();

  // Lecturas adicionales soportadas por el backend actual.
  Future<Campus> getCampusById(String id);
  Future<Building> getBuildingById(String id);
  Future<Room> getRoomById(String id);
  Future<Structure> getStructureById(String id);
  Future<Category> getCategoryById(String id);
  Future<List<Room>> searchRooms(String term);
  Future<List<Room>> getRoomsFiltered({String? buildingId, String? categoryId});
  Future<List<Structure>> getStructuresFiltered({String? campusId, String? categoryId});
  Future<List<BuildingLocationDto>> getBuildingLocations({String? campusId});
  Future<List<StructureLocationDto>> getStructureLocations({String? campusId});
}
