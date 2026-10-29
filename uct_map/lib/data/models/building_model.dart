import '../../domain/entities/building.dart';

class BuildingModel extends Building {
  const BuildingModel({
    required super.id,
    required super.campusId,
    required super.name,
    required super.floorsCount,
    required super.latitude,
    required super.longitude,
    super.rooms,
    super.schedule,
    super.services,
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    return BuildingModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      campusId: (json['campusId'] ?? json['CampusId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      floorsCount: (json['floorsCount'] ?? json['FloorsCount'] ?? 1) as int,
      latitude: (json['latitude'] ?? json['Latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['Longitude'] ?? 0.0).toDouble(),
      schedule: (json['schedule'] ?? json['Schedule'] ?? '').toString(),
      services: ((json['services'] ?? json['Services']) as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}
