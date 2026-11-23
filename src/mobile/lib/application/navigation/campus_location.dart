import '../../data/models/campus_location_dto.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/building.dart';
import '../../domain/entities/campus.dart';
import '../../domain/entities/room.dart';
import '../../domain/entities/campus_map_target.dart';
import '../../domain/repositories/campus_repository.dart';

class LocationUnavailable implements Exception {}

class CampusLocation {
  const CampusLocation({
    required this.campus,
    this.building,
    this.structure,
    this.room,
  });
  final Campus campus;
  final Building? building;
  final StructureLocationDto? structure;
  final Room? room;
  String get name => room?.name ?? structure?.name ?? building!.name;
}

Future<CampusLocation> resolveCampusLocation(
  CampusRepository repository,
  CampusMapTarget target,
) async {
  final locationId = target.locationId;
  if (locationId != null) {
    try {
      return await resolveCampusLocation(
        repository,
        CampusMapTarget.structure(locationId),
      );
    } on NotFoundException {
      return resolveCampusLocation(
        repository,
        CampusMapTarget.building(locationId),
      );
    }
  }
  final structureId = target.structureId;
  if (structureId != null) {
    if (structureId.trim().isEmpty) throw LocationUnavailable();
    final entity = await repository.getStructureById(structureId);
    if (entity.id != structureId || entity.campusId.isEmpty) {
      throw LocationUnavailable();
    }
    final locations = await repository.getStructureLocations(
      campusId: entity.campusId,
    );
    final location = locations
        .where((l) => l.id == structureId && l.campusId == entity.campusId)
        .firstOrNull;
    if (location == null) throw LocationUnavailable();
    _checkCoordinates(location.location.latitude, location.location.longitude);
    final campus = await repository.getCampusById(location.campusId);
    if (campus.id != location.campusId) throw LocationUnavailable();
    return CampusLocation(campus: campus, structure: location);
  }
  final buildingId = target.buildingId;
  if (buildingId == null || buildingId.trim().isEmpty) {
    throw LocationUnavailable();
  }
  final entity = await repository.getBuildingById(buildingId);
  if (entity.id != buildingId || entity.campusId.isEmpty) {
    throw LocationUnavailable();
  }
  final locations = await repository.getBuildingLocations(
    campusId: entity.campusId,
  );
  final location = locations
      .where((l) => l.id == buildingId && l.campusId == entity.campusId)
      .firstOrNull;
  if (location == null) throw LocationUnavailable();
  _checkCoordinates(location.location.latitude, location.location.longitude);
  final campus = await repository.getCampusById(location.campusId);
  if (campus.id != location.campusId) throw LocationUnavailable();
  Room? room;
  if (target.roomId != null) {
    room = await repository.getRoomById(target.roomId!);
    if (room.id != target.roomId || room.buildingId != buildingId) {
      throw LocationUnavailable();
    }
  }
  return CampusLocation(
    campus: campus,
    room: room,
    building: Building(
      id: location.id,
      campusId: location.campusId,
      name: location.name,
      floorsCount: location.floorsCount,
      latitude: location.location.latitude,
      longitude: location.location.longitude,
      schedule: location.schedule,
      services: location.services,
    ),
  );
}

void _checkCoordinates(double latitude, double longitude) {
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    throw LocationUnavailable();
  }
}
