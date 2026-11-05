import '../../domain/entities/campus.dart';
import 'building_model.dart';

class CampusModel extends Campus {
  const CampusModel({
    required super.id,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    super.zoom,
    super.pitch,
    super.bearing,
    super.buildings,
    super.structures,
  });

  factory CampusModel.fromJson(Map<String, dynamic> json) {
    final rawBuildings =
        (json['buildings'] ?? json['Buildings'] ?? []) as List<dynamic>;

    return CampusModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      address: (json['address'] ?? json['Address'] ?? '').toString(),
      latitude: (json['latitude'] ?? json['Latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['Longitude'] ?? 0.0).toDouble(),
      zoom: Campus.cameraValue(json, 'zoom', 0, 22),
      pitch: Campus.cameraValue(json, 'pitch', 0, 85),
      bearing: Campus.cameraValue(json, 'bearing', -180, 180),
      buildings: rawBuildings
          .whereType<Map<String, dynamic>>()
          .map((building) => BuildingModel.fromJson(building))
          .toList(),
      structures: const [],
    );
  }
}
