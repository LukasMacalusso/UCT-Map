/// Entidad estructura dentro de un Campus.
class Structure {
  final String id;
  final String campusId;
  final String categoryId;
  final String name;
  final double latitude;
  final double longitude;

  const Structure({
    required this.id,
    required this.campusId,
    required this.categoryId,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Structure.fromJson(Map<String, dynamic> json) {
    final coords =
        json['coordinates'] ?? json['Coordinates'] ?? json['coordenadas'] ?? {};

    return Structure(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      campusId: (json['campusId'] ?? json['CampusId'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['CategoryId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      latitude:
          (coords['latitude'] ?? coords['Latitude'] ?? coords['latitud'] ?? 0.0)
              .toDouble(),
      longitude:
          (coords['longitude'] ??
                  coords['Longitude'] ??
                  coords['longitud'] ??
                  0.0)
              .toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campusId': campusId,
    'categoryId': categoryId,
    'name': name,
    'coordinates': {'latitude': latitude, 'longitude': longitude},
  };
}
