import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/env_config.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/problem_details.dart';
import '../../domain/entities/lost_object.dart';
import '../models/lost_object_dto.dart';

/// Datasource remoto encargado de la comunicación con el microservicio de Incidentes
/// (submódulo de Lost Objects) expuesto en ASP.NET Core mediante Docker / API Gateway.
class LostObjectsRemoteDataSource {
  LostObjectsRemoteDataSource({
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
    Duration? timeout,
  })  : _client = client ?? ApiClientProvider.defaultClient,
        _baseUrl = _normalizeBaseUrl(baseUrl ?? _resolveDefaultBaseUrl()),
        _tokenProvider = tokenProvider ?? (() => ApiClientProvider.session.token),
        _timeout = timeout ?? EnvConfig.apiTimeout;

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _tokenProvider;
  final Duration _timeout;

  String get baseUrl => _baseUrl;

  /// Resuelve la URL base predeterminada:
  /// En emulador Android mapea localhost/127.0.0.1 a 10.0.2.2 automáticamente.
  static String _resolveDefaultBaseUrl() {
    final configured = EnvConfig.apiBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (configured.contains('localhost')) {
        return configured.replaceAll('localhost', '10.0.2.2');
      }
      if (configured.contains('127.0.0.1')) {
        return configured.replaceAll('127.0.0.1', '10.0.2.2');
      }
    }
    return configured;
  }

  static String _normalizeBaseUrl(String url) {
    var clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  /// Construye los encabezados requeridos para la petición.
  Map<String, String> _buildHeaders({bool includeContentType = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    final token = _tokenProvider();
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    return headers;
  }

  /// Resuelve la [Uri] completa agregando los query parameters opcionales.
  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final full = '$_baseUrl$cleanPath';
    final uri = Uri.parse(full);
    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }
    final stringParams = queryParams.map(
      (k, v) => MapEntry(k, v?.toString() ?? ''),
    );
    return uri.replace(queryParameters: stringParams);
  }

  /// Procesa las respuestas de error y lanza excepciones tipadas o ProblemDetails RFC 7807.
  Never _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    final problem = ProblemDetails.tryParse(statusCode, body);
    if (problem != null) {
      throw ProblemDetailsException(problem);
    }

    throw ApiException.fromResponse(statusCode, body);
  }

  /// POST /api/incident/lost-objects
  ///
  /// Crea un nuevo objeto perdido. Valida previamente que [dto.photoUrl] sea una URL absoluta.
  Future<CreateLostObjectResponse> createLostObject(CreateLostObjectDto dto) async {
    // 1. Validaciones previas en cliente
    dto.validate();

    final uri = _buildUri(ApiEndpoints.incidentLostObjects);
    final headers = _buildHeaders(includeContentType: true);
    final body = jsonEncode(dto.toJson());

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return CreateLostObjectResponse.fromJson(decoded);
        }
        throw const ApiException('Respuesta de creación en formato inválido.', 201);
      }

      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión con el servidor: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Fallo al conectar con el API Gateway: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al registrar el objeto perdido.');
    }
  }

  /// GET /api/incident/lost-objects
  ///
  /// Retorna la lista paginada de objetos perdidos aplicando los filtros enviados.
  Future<PaginatedLostObjectsResponse> getLostObjects({
    LostObjectFilterParams? filter,
  }) async {
    final queryParams = filter?.toQueryParams() ??
        const LostObjectFilterParams().toQueryParams();

    final uri = _buildUri(ApiEndpoints.incidentLostObjects, queryParams);
    final headers = _buildHeaders(includeContentType: false);

    try {
      final response = await _client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return PaginatedLostObjectsResponse.fromJson(decoded);
        }
        throw const ApiException('Respuesta de listado en formato inválido.', 200);
      }

      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión con el servidor: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Fallo al consultar objetos perdidos: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al consultar objetos perdidos.');
    }
  }

  /// PATCH /api/incident/lost-objects/{id}/lost/status
  ///
  /// Actualiza el estado de un objeto perdido. Retorna exitosamente ante 204 No Content.
  Future<void> updateStatus(String id, LostObjectStatus newStatus) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('El id del objeto no puede estar vacío.');
    }

    final path = ApiEndpoints.incidentLostObjectStatus(id.trim());
    final uri = _buildUri(path);
    final headers = _buildHeaders(includeContentType: true);
    final body = jsonEncode({'status': newStatus.value});

    try {
      final response = await _client
          .patch(uri, headers: headers, body: body)
          .timeout(_timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      }

      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión al actualizar estado: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Fallo de red al actualizar estado: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al actualizar el estado del objeto.');
    }
  }
}
