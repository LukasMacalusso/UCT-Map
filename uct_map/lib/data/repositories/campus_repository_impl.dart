import '../models/campus_location_dto.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/campus.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/structure.dart';
import '../../domain/repositories/campus_repository.dart';
import '../datasources/campus_remote_ds.dart';

class CampusRepositoryImpl implements CampusRepository {
  final CampusRemoteDataSource remoteDataSource;

  CampusRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Campus>> getCampuses() {
    return remoteDataSource.getCampuses();
  }

  @override
  Future<List<Building>> getBuildings(String campusId) {
    return remoteDataSource.getBuildings(campusId);
  }

  @override
  Future<List<Room>> getRooms(String buildingId) {
    return remoteDataSource.getRooms(buildingId);
  }

  @override
  Future<List<Structure>> getStructures(String campusId) {
    return remoteDataSource.getStructures(campusId);
  }

  @override
  Future<List<Category>> getCategories() {
    return remoteDataSource.getCategories();
  }
  @override
  Future<Campus> getCampusById(String id) => remoteDataSource.getCampusById(id);
  @override
  Future<Building> getBuildingById(String id) => remoteDataSource.getBuildingById(id);
  @override
  Future<Room> getRoomById(String id) => remoteDataSource.getRoomById(id);
  @override
  Future<Structure> getStructureById(String id) => remoteDataSource.getStructureById(id);
  @override
  Future<Category> getCategoryById(String id) => remoteDataSource.getCategoryById(id);
  @override
  Future<List<Room>> searchRooms(String term) => remoteDataSource.searchRooms(term);
  @override
  Future<List<Room>> getRoomsFiltered({String? buildingId, String? categoryId}) =>
      remoteDataSource.getRoomsFiltered(buildingId: buildingId, categoryId: categoryId);
  @override
  Future<List<Structure>> getStructuresFiltered({String? campusId, String? categoryId}) =>
      remoteDataSource.getStructuresFiltered(campusId: campusId, categoryId: categoryId);
  @override
  Future<List<BuildingLocationDto>> getBuildingLocations({String? campusId}) =>
      remoteDataSource.getBuildingLocations(campusId: campusId);
  @override
  Future<List<StructureLocationDto>> getStructureLocations({String? campusId}) =>
      remoteDataSource.getStructureLocations(campusId: campusId);
}
