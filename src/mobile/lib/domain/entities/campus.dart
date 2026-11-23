import 'building.dart';
import 'structure.dart';

/// Entidad Campus universitario.
class Campus {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? zoom;
  final double? pitch;
  final double? bearing;
  final List<Building> buildings;
  final List<Structure> structures;

  const Campus({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.zoom,
    this.pitch,
    this.bearing,
    this.buildings = const [],
    this.structures = const [],
  });

  static double? cameraValue(
    Map<String, dynamic> json,
    String key,
    double min,
    double max,
  ) {
    final value =
        json[key] ?? json['${key[0].toUpperCase()}${key.substring(1)}'];
    if (value == null) return null;
    if (value is! num || !value.isFinite || value < min || value > max)
      throw FormatException('Valor de cámara inválido: $key');
    return value.toDouble();
  }

  factory Campus.fromJson(Map<String, dynamic> json) {
    final coords =
        json['coordinates'] ?? json['Coordinates'] ?? json['coordenadas'] ?? {};

    final rawBuildings =
        (json['buildings'] ?? json['Buildings'] ?? json['edificios'] ?? [])
            as List<dynamic>;

    final rawStructures =
        (json['structures'] ?? json['Structures'] ?? json['estructuras'] ?? [])
            as List<dynamic>;

    final buildings = rawBuildings
        .whereType<Map<String, dynamic>>()
        .map((building) => Building.fromJson(building))
        .toList();

    final structures = rawStructures
        .whereType<Map<String, dynamic>>()
        .map((structure) => Structure.fromJson(structure))
        .toList();

    return Campus(
      id: (json['id_campus'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['nombre'] ?? json['name'] ?? json['Name'] ?? '').toString(),
      address: (json['direccion'] ?? json['address'] ?? json['Address'] ?? '')
          .toString(),
      latitude:
          (coords['latitud'] ?? coords['latitude'] ?? coords['Latitude'] ?? 0.0)
              .toDouble(),
      longitude:
          (coords['longitud'] ??
                  coords['longitude'] ??
                  coords['Longitude'] ??
                  0.0)
              .toDouble(),
      zoom: cameraValue(json, 'zoom', 0, 22),
      pitch: cameraValue(json, 'pitch', 0, 85),
      bearing: cameraValue(json, 'bearing', -180, 180),
      buildings: buildings,
      structures: structures,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'coordinates': {'latitude': latitude, 'longitude': longitude},
    if (zoom != null) 'zoom': zoom,
    if (pitch != null) 'pitch': pitch,
    if (bearing != null) 'bearing': bearing,
    'buildings': buildings.map((building) {
      return building.toJson();
    }).toList(),
    'structures': structures.map((structure) {
      return structure.toJson();
    }).toList(),
  };
}
