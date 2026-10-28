import '../../domain/entities/ticket.dart';
import 'lost_object_dto.dart';

/// DTO para los detalles de la queja al crear un reporte.
class CreateComplaintDto {
  final String title;
  final String description;
  final ComplaintStatus status;

  const CreateComplaintDto({
    required this.title,
    required this.description,
    this.status = ComplaintStatus.claim,
  });

  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'description': description.trim(),
        'status': status.value,
      };
}

/// DTO para crear un nuevo Ticket/Reporte (POST /api/incident/reports).
class CreateReportDto {
  final String structureRefId;
  final TicketStatus ticketType;
  final bool isActive;
  final DateTime? reportedAt;
  final String? lostObjectId;
  final CreateComplaintDto? complaint;

  const CreateReportDto({
    required this.structureRefId,
    this.ticketType = TicketStatus.pending,
    this.isActive = true,
    this.reportedAt,
    this.lostObjectId,
    this.complaint,
  });

  /// Valida las reglas de negocio y tipos antes de enviar la petición.
  void validate() {
    if (structureRefId.trim().isEmpty) {
      throw ArgumentError('El structureRefId es obligatorio.');
    }
    if (!CreateLostObjectDto.isValidUuid(structureRefId)) {
      throw ArgumentError(
        'El structureRefId debe ser un UUID válido (ej. a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d).',
      );
    }
    if (complaint != null) {
      if (complaint!.title.trim().isEmpty) {
        throw ArgumentError('El título de la queja es obligatorio.');
      }
      if (complaint!.title.trim().length < 3) {
        throw ArgumentError('El título de la queja debe tener al menos 3 caracteres.');
      }
      if (complaint!.description.trim().isEmpty) {
        throw ArgumentError('La descripción de la queja es obligatoria.');
      }
      if (complaint!.description.trim().length < 5) {
        throw ArgumentError('La descripción de la queja debe tener al menos 5 caracteres.');
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'structureRefId': structureRefId.trim(),
        'ticketType': ticketType.value,
        'isActive': isActive,
        'reportedAt': (reportedAt ?? DateTime.now()).toUtc().toIso8601String(),
        if (lostObjectId != null && lostObjectId!.trim().isNotEmpty)
          'lostObjectId': lostObjectId!.trim(),
        if (complaint != null) 'complaint': complaint!.toJson(),
      };
}

/// DTO de respuesta para la creación de reporte (201 Created).
class CreateReportResponse {
  final String id;

  const CreateReportResponse({required this.id});

  factory CreateReportResponse.fromJson(Map<String, dynamic> json) {
    return CreateReportResponse(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id};

  @override
  String toString() => 'CreateReportResponse(id: $id)';
}

/// Parámetros de consulta y filtrado para GET /api/incident/reports.
class ReportFilterParams {
  final String? userRefId;
  final String? structureRefId;
  final TicketStatus? type;
  final bool? isActive;
  final String? lostObjectId;
  final String? complaintTitle;
  final String? complaintDescription;
  final ComplaintStatus? complaintStatus;
  final String sortBy;
  final bool descending;
  final int page;
  final int pageSize;

  const ReportFilterParams({
    this.userRefId,
    this.structureRefId,
    this.type,
    this.isActive,
    this.lostObjectId,
    this.complaintTitle,
    this.complaintDescription,
    this.complaintStatus,
    this.sortBy = 'ReportedAt',
    this.descending = true,
    this.page = 1,
    this.pageSize = 10,
  });

  /// Mapea los filtros a los query parameters soportados por ASP.NET Core:
  /// complaintDetails.title, complaintDetails.description, complaintDetails.status, etc.
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (userRefId != null && userRefId!.trim().isNotEmpty) {
      params['userRefId'] = userRefId!.trim();
    }
    if (structureRefId != null && structureRefId!.trim().isNotEmpty) {
      params['structureRefId'] = structureRefId!.trim();
    }
    if (type != null) {
      params['type'] = type!.value.toString();
    }
    if (isActive != null) {
      params['isActive'] = isActive!.toString();
    }
    if (lostObjectId != null && lostObjectId!.trim().isNotEmpty) {
      params['lostObjectId'] = lostObjectId!.trim();
    }
    if (complaintTitle != null && complaintTitle!.trim().isNotEmpty) {
      params['complaintDetails.title'] = complaintTitle!.trim();
    }
    if (complaintDescription != null && complaintDescription!.trim().isNotEmpty) {
      params['complaintDetails.description'] = complaintDescription!.trim();
    }
    if (complaintStatus != null) {
      params['complaintDetails.status'] = complaintStatus!.value.toString();
    }

    params['sortBy'] = sortBy;
    params['descending'] = descending.toString();
    params['page'] = (page < 1 ? 1 : page).toString();
    params['pageSize'] = pageSize.clamp(1, 10).toString();

    return params;
  }

  ReportFilterParams copyWith({
    String? userRefId,
    String? structureRefId,
    TicketStatus? type,
    bool? isActive,
    String? lostObjectId,
    String? complaintTitle,
    String? complaintDescription,
    ComplaintStatus? complaintStatus,
    String? sortBy,
    bool? descending,
    int? page,
    int? pageSize,
  }) {
    return ReportFilterParams(
      userRefId: userRefId ?? this.userRefId,
      structureRefId: structureRefId ?? this.structureRefId,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      lostObjectId: lostObjectId ?? this.lostObjectId,
      complaintTitle: complaintTitle ?? this.complaintTitle,
      complaintDescription: complaintDescription ?? this.complaintDescription,
      complaintStatus: complaintStatus ?? this.complaintStatus,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

/// Respuesta paginada para GET /api/incident/reports (200 OK).
class PaginatedReportsResponse {
  final List<Ticket> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedReportsResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory PaginatedReportsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = <Ticket>[];

    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          itemsList.add(Ticket.fromJson(it));
        }
      }
    }

    return PaginatedReportsResponse(
      items: itemsList,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? itemsList.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'totalCount': totalCount,
        'page': page,
        'pageSize': pageSize,
        'totalPages': totalPages,
      };

  @override
  String toString() =>
      'PaginatedReportsResponse(total: $totalCount, page: $page/$totalPages, items: ${items.length})';
}
