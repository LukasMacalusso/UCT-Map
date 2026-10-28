import 'package:flutter/foundation.dart';

/// Enumeración de Estados generales del Ticket (Incident Service - ASP.NET Core):
/// 0: Pending, 1: In_Process, 2: Resolved, 3: Dismissed.
enum TicketStatus {
  pending(0, 'Pending', 'Pendiente'),
  inProcess(1, 'In_Process', 'En Proceso'),
  resolved(2, 'Resolved', 'Resuelto'),
  dismissed(3, 'Dismissed', 'Desestimado');

  final int value;
  final String apiName;
  final String label;

  const TicketStatus(this.value, this.apiName, this.label);

  /// Parsea tanto números (0, 1, 2, 3) como strings ("Pending", "In_Process", etc.).
  static TicketStatus fromValue(dynamic val) {
    if (val == null) return TicketStatus.pending;

    if (val is int) {
      for (final s in TicketStatus.values) {
        if (s.value == val) return s;
      }
      return TicketStatus.pending;
    }

    final str = val.toString().trim();
    final asInt = int.tryParse(str);
    if (asInt != null) {
      for (final s in TicketStatus.values) {
        if (s.value == asInt) return s;
      }
    }

    final normalized = str.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'in_process':
      case 'inprocess':
      case 'en_proceso':
      case 'enproceso':
        return TicketStatus.inProcess;
      case 'resolved':
      case 'resuelto':
        return TicketStatus.resolved;
      case 'dismissed':
      case 'desestimado':
      case 'descartado':
        return TicketStatus.dismissed;
      case 'pending':
      case 'pendiente':
      default:
        return TicketStatus.pending;
    }
  }
}

/// Enumeración de Estado de Queja / Reclamo (Complainenum):
/// 0: Claim (Reclamo)
/// 1: Found (Hallazgo)
/// 2: Match (Coincidencia)
/// 3: Pickup (Retiro)
enum ComplaintStatus {
  claim(0, 'Claim', 'Reclamo'),
  found(1, 'Found', 'Hallazgo'),
  match(2, 'Match', 'Coincidencia'),
  pickup(3, 'Pickup', 'Retiro');

  final int value;
  final String apiName;
  final String label;

  const ComplaintStatus(this.value, this.apiName, this.label);

  /// Parsea tanto números (0..3) como cadenas ("Claim", "Found", etc.).
  static ComplaintStatus fromValue(dynamic val) {
    if (val == null) return ComplaintStatus.claim;

    if (val is int) {
      for (final s in ComplaintStatus.values) {
        if (s.value == val) return s;
      }
      return ComplaintStatus.claim;
    }

    final str = val.toString().trim();
    final asInt = int.tryParse(str);
    if (asInt != null) {
      for (final s in ComplaintStatus.values) {
        if (s.value == asInt) return s;
      }
    }

    final normalized = str.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (normalized) {
      case 'found':
      case 'hallazgo':
        return ComplaintStatus.found;
      case 'match':
      case 'coincidencia':
        return ComplaintStatus.match;
      case 'pickup':
      case 'retiro':
        return ComplaintStatus.pickup;
      case 'claim':
      case 'reclamo':
      default:
        return ComplaintStatus.claim;
    }
  }
}

/// Objeto de valor que representa los detalles de la queja / reclamo.
@immutable
class ComplaintDetails {
  final String title;
  final String description;
  final ComplaintStatus status;

  const ComplaintDetails({
    required this.title,
    required this.description,
    this.status = ComplaintStatus.claim,
  });

  factory ComplaintDetails.fromJson(Map<String, dynamic> json) {
    return ComplaintDetails(
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      status: ComplaintStatus.fromValue(json['status'] ?? json['Status']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'status': status.value,
      };

  ComplaintDetails copyWith({
    String? title,
    String? description,
    ComplaintStatus? status,
  }) {
    return ComplaintDetails(
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComplaintDetails &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          description == other.description &&
          status == other.status;

  @override
  int get hashCode => title.hashCode ^ description.hashCode ^ status.hashCode;

  @override
  String toString() =>
      'ComplaintDetails(title: $title, status: ${status.name})';
}

/// Entidad de dominio que representa un Reporte / Ticket en el microservicio de Incidentes.
@immutable
class Ticket {
  final String id;
  final String? userRefId;
  final String structureRefId;
  final TicketStatus ticketType;
  final bool isActive;
  final DateTime reportedAt;
  final ComplaintDetails? complaintDetails;
  final String? lostObjectId;

  const Ticket({
    required this.id,
    this.userRefId,
    required this.structureRefId,
    required this.ticketType,
    required this.isActive,
    required this.reportedAt,
    this.complaintDetails,
    this.lostObjectId,
  });

  /// Parsea la estructura JSON devuelta por el backend:
  /// {
  ///   "id": "671fb3e98971f49673981299",
  ///   "userRefId": "27da61e1-cb64-46e6-96f0-394a44d08577",
  ///   "structureRefId": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
  ///   "ticketType": 0,
  ///   "isActive": true,
  ///   "reportedAt": "2026-10-28T15:30:00Z",
  ///   "complaintDetails": { ... },
  ///   "lostObjectId": "671fb2c58971f49673981234"
  /// }
  factory Ticket.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['reportedAt'] ?? json['ReportedAt'] ?? json['dateReport'];
    if (rawDate != null) {
      parsedDate = DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    ComplaintDetails? parsedComplaint;
    final rawComplaint = json['complaintDetails'] ?? json['complaint'] ?? json['ComplaintDetails'];
    if (rawComplaint is Map<String, dynamic>) {
      parsedComplaint = ComplaintDetails.fromJson(rawComplaint);
    }

    return Ticket(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userRefId: json['userRefId']?.toString(),
      structureRefId: (json['structureRefId'] ?? json['StructureRefId'] ?? '').toString(),
      ticketType: TicketStatus.fromValue(json['ticketType'] ?? json['type'] ?? json['TicketType']),
      isActive: (json['isActive'] ?? json['IsActive'] ?? true) as bool,
      reportedAt: parsedDate,
      complaintDetails: parsedComplaint,
      lostObjectId: json['lostObjectId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        if (userRefId != null) 'userRefId': userRefId,
        'structureRefId': structureRefId,
        'ticketType': ticketType.value,
        'isActive': isActive,
        'reportedAt': reportedAt.toUtc().toIso8601String(),
        if (complaintDetails != null) 'complaintDetails': complaintDetails!.toJson(),
        if (lostObjectId != null && lostObjectId!.isNotEmpty) 'lostObjectId': lostObjectId,
      };

  Ticket copyWith({
    String? id,
    String? userRefId,
    String? structureRefId,
    TicketStatus? ticketType,
    bool? isActive,
    DateTime? reportedAt,
    ComplaintDetails? complaintDetails,
    String? lostObjectId,
  }) {
    return Ticket(
      id: id ?? this.id,
      userRefId: userRefId ?? this.userRefId,
      structureRefId: structureRefId ?? this.structureRefId,
      ticketType: ticketType ?? this.ticketType,
      isActive: isActive ?? this.isActive,
      reportedAt: reportedAt ?? this.reportedAt,
      complaintDetails: complaintDetails ?? this.complaintDetails,
      lostObjectId: lostObjectId ?? this.lostObjectId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userRefId == other.userRefId &&
          structureRefId == other.structureRefId &&
          ticketType == other.ticketType &&
          isActive == other.isActive &&
          reportedAt == other.reportedAt &&
          complaintDetails == other.complaintDetails &&
          lostObjectId == other.lostObjectId;

  @override
  int get hashCode =>
      id.hashCode ^
      userRefId.hashCode ^
      structureRefId.hashCode ^
      ticketType.hashCode ^
      isActive.hashCode ^
      reportedAt.hashCode ^
      complaintDetails.hashCode ^
      lostObjectId.hashCode;

  @override
  String toString() =>
      'Ticket(id: $id, type: ${ticketType.name}, structure: $structureRefId, active: $isActive)';
}
