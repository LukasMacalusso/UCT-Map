import 'package:flutter/foundation.dart';

/// Enum para representar los estados de un objeto perdido según la especificación del backend:
/// 0: Pending, 1: In_Process, 2: Resolved, 3: Canceled.
enum LostObjectStatus {
  pending(0, 'Pending', 'Pendiente'),
  inProcess(1, 'In_Process', 'En Proceso'),
  resolved(2, 'Resolved', 'Resuelto'),
  canceled(3, 'Canceled', 'Cancelado');

  final int value;
  final String apiName;
  final String label;

  const LostObjectStatus(this.value, this.apiName, this.label);

  /// Parsea tanto números (0, 1, 2, 3) como strings ("Pending", "In_Process", etc.)
  static LostObjectStatus fromValue(dynamic val) {
    if (val == null) return LostObjectStatus.pending;

    if (val is int) {
      for (final s in LostObjectStatus.values) {
        if (s.value == val) return s;
      }
      return LostObjectStatus.pending;
    }

    final str = val.toString().trim();
    final asInt = int.tryParse(str);
    if (asInt != null) {
      for (final s in LostObjectStatus.values) {
        if (s.value == asInt) return s;
      }
    }

    final normalized = str.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'in_process':
      case 'inprocess':
      case 'en_proceso':
      case 'enproceso':
        return LostObjectStatus.inProcess;
      case 'resolved':
      case 'resuelto':
        return LostObjectStatus.resolved;
      case 'canceled':
      case 'cancelled':
      case 'cancelado':
        return LostObjectStatus.canceled;
      case 'pending':
      case 'pendiente':
      default:
        return LostObjectStatus.pending;
    }
  }
}

/// Entidad de dominio que representa un objeto perdido reportado en el campus.
@immutable
class LostObject {
  final String id;
  final String title;
  final String description;
  final DateTime? date;
  final LostObjectStatus status;
  final String photoUrl;
  final String structureId;

  const LostObject({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.photoUrl,
    required this.structureId,
    this.date,
  });

  /// Crea una instancia a partir del JSON devuelto por el backend:
  /// {
  ///   "id": "671fb2c58971f49673981234",
  ///   "title": "Mochila negra",
  ///   "description": "Olvidada en biblioteca central 2do piso",
  ///   "date": "2026-10-28T15:30:00Z",
  ///   "status": "Pending",
  ///   "photoUrl": "https://dominio.com/foto.jpg",
  ///   "structureId": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d"
  /// }
  factory LostObject.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date'] ?? json['reportedAt'] ?? json['Date'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString())?.toLocal();
    }

    return LostObject(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      date: parsedDate,
      status: LostObjectStatus.fromValue(json['status'] ?? json['Status']),
      photoUrl: (json['photoUrl'] ?? json['PhotoUrl'] ?? '').toString(),
      structureId: (json['structureId'] ?? json['StructureId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'title': title,
        'description': description,
        if (date != null) 'date': date!.toIso8601String(),
        'status': status.apiName,
        'photoUrl': photoUrl,
        'structureId': structureId,
      };

  LostObject copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    LostObjectStatus? status,
    String? photoUrl,
    String? structureId,
  }) {
    return LostObject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      structureId: structureId ?? this.structureId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LostObject &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          date == other.date &&
          status == other.status &&
          photoUrl == other.photoUrl &&
          structureId == other.structureId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      date.hashCode ^
      status.hashCode ^
      photoUrl.hashCode ^
      structureId.hashCode;

  @override
  String toString() =>
      'LostObject(id: $id, title: $title, status: ${status.name}, structureId: $structureId)';
}
