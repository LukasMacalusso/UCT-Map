import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_client_provider.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/lost_item.dart';
import '../../domain/entities/report.dart';
import '../../domain/repositories/incident_repository.dart';

/// Datasource remoto para consumir /api/incident a través del API Gateway.
class IncidentRemoteDataSource implements IncidentRepository {
  IncidentRemoteDataSource({http.Client? client, ApiConfig? config})
    : _client = client ?? ApiClientProvider.defaultClient,
      _config = config ?? ApiConfig();

  final http.Client _client;
  final ApiConfig _config;

  @override
  Future<List<LostItem>> getLostItems({
    String? campus,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{};
    if (campus != null && campus != 'Todos') queryParams['campus'] = campus;
    if (category != null && category != 'Todas')
      queryParams['category'] = category;

    final uri = _config.uri(ApiEndpoints.incidentLostItems, queryParams);
    try {
      final res = await _client.get(uri).timeout(_config.timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((item) => LostItem.fromJson(item))
              .toList();
        }
      }
      throw ApiException.fromResponse(res.statusCode, res.body);
    } on http.ClientException {
      return _filterMockLostItems(campus, category);
    } on TimeoutException {
      return _filterMockLostItems(campus, category);
    }
  }

  @override
  Future<LostItem> createLostItem(LostItem item) async {
    final uri = _config.uri(ApiEndpoints.incidentLostItems);
    try {
      final res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(item.toJson()),
          )
          .timeout(_config.timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return LostItem.fromJson(decoded);
        }
      }
      throw ApiException.fromResponse(res.statusCode, res.body);
    } on http.ClientException {
      // Fallback local: devolver el item como creado
      return item;
    } on TimeoutException {
      throw const NetworkException(
        'Tiempo de espera agotado al reportar objeto.',
      );
    }
  }

  @override
  Future<List<Report>> getReports({String? campus}) async {
    final queryParams = <String, dynamic>{};
    if (campus != null && campus != 'Todos') queryParams['campus'] = campus;

    final uri = _config.uri(ApiEndpoints.incidentReports, queryParams);
    try {
      final res = await _client.get(uri).timeout(_config.timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((r) => Report.fromJson(r))
              .toList();
        }
      }
      throw ApiException.fromResponse(res.statusCode, res.body);
    } on http.ClientException {
      return _filterMockReports(campus);
    } on TimeoutException {
      return _filterMockReports(campus);
    }
  }

  @override
  Future<Report> createReport(Report report) async {
    final uri = _config.uri(ApiEndpoints.incidentReports);
    try {
      final res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(report.toJson()),
          )
          .timeout(_config.timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          return Report.fromJson(decoded);
        }
      }
      throw ApiException.fromResponse(res.statusCode, res.body);
    } on http.ClientException {
      return report;
    } on TimeoutException {
      throw const NetworkException(
        'Tiempo de espera agotado al crear reporte.',
      );
    }
  }

  @override
  Future<bool> updateTicketStatus(String ticketId, String status) async {
    final uri = _config.uri(ApiEndpoints.incidentTicketStatus(ticketId));
    try {
      final res = await _client
          .patch(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status}),
          )
          .timeout(_config.timeout);

      return res.statusCode == 200 || res.statusCode == 204;
    } on Exception {
      return false;
    }
  }

  List<LostItem> _filterMockLostItems(String? campus, String? category) {
    var items = List<LostItem>.from(mockLostItems);
    if (campus != null && campus != 'Todos') {
      items = items.where((i) => i.campus == campus).toList();
    }
    if (category != null && category != 'Todas') {
      items = items.where((i) => i.category == category).toList();
    }
    return items;
  }

  List<Report> _filterMockReports(String? campus) {
    var reports = List<Report>.from(mockReports);
    if (campus != null && campus != 'Todos') {
      reports = reports.where((r) => r.campus == campus).toList();
    }
    return reports;
  }
}
