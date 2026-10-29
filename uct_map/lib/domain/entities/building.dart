import 'room.dart';

/// Entidad Edificio dentro de un Campus.
class Building {
  final String id;
  final String campusId;
  final String name;
  final int floorsCount;
  final double latitude;
  final double longitude;
  final List<Room> rooms;
  final String schedule;
  final List<String> services;

  const Building({
    required this.id,
    required this.campusId,
    required this.name,
    required this.floorsCount,
    required this.latitude,
    required this.longitude,
    this.rooms = const [],
    this.schedule = '',
    this.services = const [],
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    final coords =
        json['coordinates'] ?? json['Coordinates'] ?? json['coordenadas'] ?? {};

    final rawRooms = (json['rooms'] ?? json['Rooms'] ?? []) as List<dynamic>;

    final rooms = rawRooms
        .whereType<Map<String, dynamic>>()
        .map((room) => Room.fromJson(room))
        .toList();

    return Building(
      id: (json['id_edificio'] ?? json['id'] ?? json['Id'] ?? '').toString(),
      campusId:
          (json['id_campus'] ?? json['campusId'] ?? json['CampusId'] ?? '')
              .toString(),
      name: (json['nombre'] ?? json['name'] ?? json['Name'] ?? '').toString(),
      floorsCount:
          (json['cant_pisos'] ??
                  json['floorsCount'] ??
                  json['FloorsCount'] ??
                  1)
              as int,
      latitude:
          (coords['latitud'] ?? coords['latitude'] ?? coords['Latitude'] ?? 0.0)
              .toDouble(),
      longitude:
          (coords['longitud'] ??
                  coords['longitude'] ??
                  coords['Longitude'] ??
                  0.0)
              .toDouble(),
      rooms: rooms,
      schedule: (json['schedule'] ?? json['Schedule'] ?? '').toString(),
      services: ((json['services'] ?? json['Services']) as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'campusId': campusId,
    'name': name,
    'floorsCount': floorsCount,
    'coordinates': {'latitude': latitude, 'longitude': longitude},
    'rooms': rooms.map((room) => room.toJson()).toList(),
    'schedule': schedule,
    'services': services,
  };
}
