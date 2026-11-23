import '../../domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.buildingId,
    required super.categoryId,
    required super.name,
    required super.floor,
    super.number,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      buildingId: (json['buildingId'] ?? json['BuildingId'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? json['CategoryId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      floor: (json['floor'] ?? json['Floor'] ?? 1) as int,
      number: json['number']?.toString() ?? json['Number']?.toString(),
    );
  }
}
