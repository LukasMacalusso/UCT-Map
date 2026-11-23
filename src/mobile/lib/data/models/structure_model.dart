import '../../domain/entities/structure.dart';

class StructureModel extends Structure {
  const StructureModel({
    required super.id,
    required super.campusId,
    required super.categoryId,
    required super.name,
    required super.latitude,
    required super.longitude,
  });

  factory StructureModel.fromJson(Map<String, dynamic> json) {
    return StructureModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      campusId: (json['campusId'] ?? json['CampusId'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['CategoryId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      latitude: (json['latitude'] ?? json['Latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['Longitude'] ?? 0.0).toDouble(),
    );
  }
}
