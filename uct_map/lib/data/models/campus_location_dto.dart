/// DTOs para endpoints /locations de Campus Service.
class CampusCoordinateDto {
  final double latitude;
  final double longitude;
  const CampusCoordinateDto({required this.latitude, required this.longitude});
  factory CampusCoordinateDto.fromJson(Map<String, dynamic> json) =>
    CampusCoordinateDto(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
}

class BuildingLocationDto {
  final String id;
  final String name;
  final CampusCoordinateDto location;
  final String campusId;
  final int floorsCount;
  final String schedule;
  final List<String> services;
  const BuildingLocationDto({required this.id, required this.name,
    required this.location, required this.campusId, required this.floorsCount,
    required this.schedule, required this.services});
  factory BuildingLocationDto.fromJson(Map<String, dynamic> json) {
    final meta = (json['metadata'] as Map).cast<String, dynamic>();
    return BuildingLocationDto(
      id: json['id'].toString(), name: json['name'].toString(),
      location: CampusCoordinateDto.fromJson((json['location'] as Map).cast<String,dynamic>()),
      campusId: meta['campusId'].toString(),
      floorsCount: (meta['floorsCount'] as num).toInt(),
      schedule: (meta['schedule'] ?? '').toString(),
      services: ((meta['services'] as List?) ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

class StructureLocationDto {
  final String id;
  final String name;
  final CampusCoordinateDto location;
  final String campusId;
  final String categoryId;
  final String categoryName;
  const StructureLocationDto({required this.id, required this.name,
    required this.location, required this.campusId, required this.categoryId,
    required this.categoryName});
  factory StructureLocationDto.fromJson(Map<String, dynamic> json) {
    final meta = (json['metadata'] as Map).cast<String,dynamic>();
    return StructureLocationDto(
      id: json['id'].toString(), name: json['name'].toString(),
      location: CampusCoordinateDto.fromJson((json['location'] as Map).cast<String,dynamic>()),
      campusId: meta['campusId'].toString(),
      categoryId: meta['categoryId'].toString(),
      categoryName: (meta['categoryName'] ?? '').toString(),
    );
  }
}
