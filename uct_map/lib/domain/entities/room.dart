/// Entidad Sala u oficina dentro de un Edificio (ms.svg - Campus Service).
class Room {
  final String id;
  final String buildingId;
  final String categoryId;
  final String name;
  final int floor;
  final String? number;

  const Room({
    required this.id,
    required this.buildingId,
    required this.categoryId,
    required this.name,
    required this.floor,
    this.number,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      buildingId: (json['buildingId'] ?? json['BuildingId'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['CategoryId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      floor: (json['floor'] ?? json['Floor'] ?? 1) as int,
      number: json['number']?.toString() ?? json['Number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'buildingId': buildingId,
    'categoryId': categoryId,
    'name': name,
    'floor': floor,
    if (number != null) 'number': number,
  };
}
