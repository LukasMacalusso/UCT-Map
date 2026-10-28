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
import '../../domain/entities/ticket.dart';
import '../models/report_dto.dart';

/// Datasource remoto para interactuar con el microservicio de Incidentes (Módulo de Reportes/Tickets)
/// expuesto a través de ASP.NET Core en Docker / API Gateway.
class ReportsRemoteDataSource {
  ReportsRemoteDataSource({
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

  /// Construye los encabezados obligatorios (Authorization: Bearer, Content-Type, Accept).
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

  /// Resuelve la [Uri] completa agregando los query parameters.
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

  /// Procesa respuestas de error y lanza ProblemDetails RFC 7807 o ApiException.
  Never _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    final problem = ProblemDetails.tryParse(statusCode, body);
    if (problem != null) {
      throw ProblemDetailsException(problem);
    }

    throw ApiException.fromResponse(statusCode, body);
  }

  /// POST /api/incident/reports
  ///
  /// Crea un nuevo reporte/ticket. El usuario se asigna automáticamente desde el JWT en el backend.
  Future<CreateReportResponse> createReport(CreateReportDto dto) async {
    dto.validate();

    final uri = _buildUri(ApiEndpoints.incidentReports);
    final headers = _buildHeaders(includeContentType: true);
    final body = jsonEncode(dto.toJson());

    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return CreateReportResponse.fromJson(decoded);
        }
        throw const ApiException('Respuesta de creación en formato inválido.', 201);
      }

      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión con el servidor: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Fallo al conectar con el API Gateway: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al registrar el reporte.');
    }
  }

  /// GET /api/incident/reports
  ///
  /// Retorna el listado paginado de tickets/reportes según los filtros indicados.
  Future<PaginatedReportsResponse> getReports({ReportFilterParams? filter}) async {
    final queryParams = filter?.toQueryParams() ??
        const ReportFilterParams().toQueryParams();

    final uri = _buildUri(ApiEndpoints.incidentReports, queryParams);
    final headers = _buildHeaders(includeContentType: false);

    try {
      final response = await _client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return PaginatedReportsResponse.fromJson(decoded);
        }
        throw const ApiException('Respuesta de listado en formato inválido.', 200);
      }

      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión con el servidor: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Fallo al consultar reportes: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al consultar reportes.');
    }
  }

  /// GET /api/incident/reports/{id}
  ///
  /// Retorna los detalles de un ticket individual por su ID.
  Future<Ticket> getReportById(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('El id del reporte no puede estar vacío.');
    }

    final path = ApiEndpoints.incidentReportDetail(id.trim());
    final uri = _buildUri(path);
    final headers = _buildHeaders(includeContentType: false);

    try {
      final response = await _client.get(uri, headers: headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return Ticket.fromJson(decoded);
        }
        throw const ApiException('Detalle del reporte en formato inválido.', 200);
      }

      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión con el servidor: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Fallo al consultar detalle del reporte: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al consultar el reporte.');
    }
  }

  /// PATCH /api/incident/reports/{id}/report/status
  ///
  /// Actualiza el estado del ticket y opcionalmente el estado de la queja.
  /// Retorna ante 204 No Content.
  Future<void> updateReportStatus(
    String id, {
    required TicketStatus status,
    ComplaintStatus? complainStatus,
  }) async {
    if (id.trim().isEmpty) {
      throw ArgumentError('El id del reporte no puede estar vacío.');
    }

    final path = ApiEndpoints.incidentReportStatus(id.trim());
    final uri = _buildUri(path);
    final headers = _buildHeaders(includeContentType: true);

    final payload = <String, dynamic>{
      'status': status.value,
      if (complainStatus != null) 'complainStatus': complainStatus.value,
    };

    try {
      final response = await _client
          .patch(uri, headers: headers, body: jsonEncode(payload))
          .timeout(_timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      }

      _handleErrorResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Error de conexión al actualizar estado del reporte: ${e.message}');
    } on http.ClientException catch (e) {
      throw NetworkException('Fallo de red al actualizar estado del reporte: ${e.message}');
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado al actualizar el reporte.');
    }
  }
}
