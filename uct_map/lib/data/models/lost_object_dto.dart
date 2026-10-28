import '../../domain/entities/lost_object.dart';

/// DTO para la creación de un nuevo Objeto Perdido (Request Body POST /api/incident/lost-objects).
class CreateLostObjectDto {
  final String title;
  final String description;
  final LostObjectStatus status;
  final String photoUrl;
  final String structureId;

  const CreateLostObjectDto({
    required this.title,
    required this.description,
    this.status = LostObjectStatus.pending,
    required this.photoUrl,
    required this.structureId,
  });

  /// Expresión regular para validar formato UUID estándar (v1-v5).
  static final RegExp uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Valida si una URL es absoluta y usa protocolo http o https.
  static bool isValidAbsoluteUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    return uri.isAbsolute &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;
  }

  /// Valida si una cadena cumple con formato UUID.
  static bool isValidUuid(String? uuid) {
    if (uuid == null || uuid.trim().isEmpty) return false;
    return uuidRegex.hasMatch(uuid.trim());
  }

  /// Ejecuta todas las validaciones del contrato antes de enviar la petición.
  /// Lanza [ArgumentError] con mensaje explicativo si alguna regla no se cumple.
  void validate() {
    if (title.trim().isEmpty) {
      throw ArgumentError('El título es obligatorio.');
    }
    if (title.trim().length < 3) {
      throw ArgumentError('El título debe tener al menos 3 caracteres.');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('La descripción es obligatoria.');
    }
    if (description.trim().length < 5) {
      throw ArgumentError('La descripción debe tener al menos 5 caracteres.');
    }
    if (!isValidUuid(structureId)) {
      throw ArgumentError(
        'El structureId debe ser un UUID válido (ej. a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d).',
      );
    }
    if (!isValidAbsoluteUrl(photoUrl)) {
      throw ArgumentError(
        'La photoUrl debe ser una URL pública absoluta válida que inicie con http:// o https://.',
      );
    }
  }

  /// Serializa a JSON según el contrato del backend:
  /// status como entero (0, 1, 2, 3).
  Map<String, dynamic> toJson() => {
        'title': title.trim(),
        'description': description.trim(),
        'status': status.value,
        'photoUrl': photoUrl.trim(),
        'structureId': structureId.trim(),
      };
}

/// DTO de respuesta para la creación exitosa (201 Created).
class CreateLostObjectResponse {
  final String id;

  const CreateLostObjectResponse({required this.id});

  factory CreateLostObjectResponse.fromJson(Map<String, dynamic> json) {
    return CreateLostObjectResponse(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id};

  @override
  String toString() => 'CreateLostObjectResponse(id: $id)';
}

/// Parámetros de consulta y filtrado para GET /api/incident/lost-objects.
class LostObjectFilterParams {
  final String? title;
  final String? structureId;
  final LostObjectStatus? status;
  final String sortBy;
  final bool descending;
  final int page;
  final int pageSize;

  const LostObjectFilterParams({
    this.title,
    this.structureId,
    this.status,
    this.sortBy = 'ReportedAt',
    this.descending = true,
    this.page = 1,
    this.pageSize = 10,
  });

  /// Convierte los parámetros al mapa de Query Parameters esperado por el backend.
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (title != null && title!.trim().isNotEmpty) {
      params['title'] = title!.trim();
    }
    if (structureId != null && structureId!.trim().isNotEmpty) {
      params['structureId'] = structureId!.trim();
    }
    if (status != null) {
      params['status'] = status!.value.toString();
    }

    params['sortBy'] = sortBy;
    params['descending'] = descending.toString();
    params['page'] = (page < 1 ? 1 : page).toString();
    params['pageSize'] = pageSize.clamp(1, 10).toString();

    return params;
  }

  LostObjectFilterParams copyWith({
    String? title,
    String? structureId,
    LostObjectStatus? status,
    String? sortBy,
    bool? descending,
    int? page,
    int? pageSize,
  }) {
    return LostObjectFilterParams(
      title: title ?? this.title,
      structureId: structureId ?? this.structureId,
      status: status ?? this.status,
      sortBy: sortBy ?? this.sortBy,
      descending: descending ?? this.descending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

/// Respuesta paginada para GET /api/incident/lost-objects (200 OK).
class PaginatedLostObjectsResponse {
  final List<LostObject> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedLostObjectsResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  factory PaginatedLostObjectsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final itemsList = <LostObject>[];

    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          itemsList.add(LostObject.fromJson(it));
        }
      }
    }

    return PaginatedLostObjectsResponse(
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
      'PaginatedLostObjectsResponse(total: $totalCount, page: $page/$totalPages, items: ${items.length})';
}
