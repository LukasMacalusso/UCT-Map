import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client_provider.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP de alto nivel para consumir las rutas del backend y microservicios
/// expuestos por el API Gateway (YARP en ASP.NET Core).
///
/// Encapsula:
/// - Construcción segura de URIs y Query Parameters mediante [ApiConfig].
/// - Serialización JSON automática en cuerpos de petición (POST, PUT, PATCH).
/// - Transformación automática de respuestas de error a la jerarquía tipada [ApiException].
/// - Conversión de errores de conectividad y timeout a [NetworkException].
class ApiClient {
  ApiClient({http.Client? client, ApiConfig? config})
    : _client = client ?? ApiClientProvider.defaultClient,
      _config = config ?? ApiConfig();

  final http.Client _client;
  final ApiConfig _config;

  ApiConfig get config => _config;
  http.Client get rawClient => _client;

  /// Resuelve la URL completa usando la configuración base.
  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    return _config.uri(path, queryParameters);
  }

  /// Ejecuta una petición GET.
  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final res = await _client
          .get(uri, headers: headers)
          .timeout(timeout ?? _config.timeout);
      _checkResponse(res);
      return res;
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        'Tiempo de espera agotado al conectar con el servidor.',
      );
    }
  }

  /// Ejecuta una petición GET y decodifica el cuerpo JSON.
  Future<T> getJson<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJson,
    Duration? timeout,
  }) async {
    final res = await get(
      path,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
    );
    final decoded = jsonDecode(res.body);
    if (fromJson != null) {
      return fromJson(decoded);
    }
    return decoded as T;
  }

  /// Ejecuta una petición POST con serialización JSON opcional.
  Future<http.Response> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final effectiveHeaders = {'Content-Type': 'application/json', ...?headers};
    final encodedBody = body != null && body is! String
        ? jsonEncode(body)
        : body;

    try {
      final res = await _client
          .post(uri, headers: effectiveHeaders, body: encodedBody)
          .timeout(timeout ?? _config.timeout);
      _checkResponse(res);
      return res;
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        'Tiempo de espera agotado al conectar con el servidor.',
      );
    }
  }

  /// Ejecuta una petición POST y decodifica la respuesta JSON.
  Future<T> postJson<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJson,
    Duration? timeout,
  }) async {
    final res = await post(
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      timeout: timeout,
    );
    final decoded = jsonDecode(res.body);
    if (fromJson != null) {
      return fromJson(decoded);
    }
    return decoded as T;
  }

  /// Ejecuta una petición PUT.
  Future<http.Response> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final effectiveHeaders = {'Content-Type': 'application/json', ...?headers};
    final encodedBody = body != null && body is! String
        ? jsonEncode(body)
        : body;

    try {
      final res = await _client
          .put(uri, headers: effectiveHeaders, body: encodedBody)
          .timeout(timeout ?? _config.timeout);
      _checkResponse(res);
      return res;
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        'Tiempo de espera agotado al conectar con el servidor.',
      );
    }
  }

  /// Ejecuta una petición PATCH.
  Future<http.Response> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final effectiveHeaders = {'Content-Type': 'application/json', ...?headers};
    final encodedBody = body != null && body is! String
        ? jsonEncode(body)
        : body;

    try {
      final res = await _client
          .patch(uri, headers: effectiveHeaders, body: encodedBody)
          .timeout(timeout ?? _config.timeout);
      _checkResponse(res);
      return res;
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        'Tiempo de espera agotado al conectar con el servidor.',
      );
    }
  }

  /// Ejecuta una petición DELETE.
  Future<http.Response> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final effectiveHeaders = {
      if (body != null) 'Content-Type': 'application/json',
      ...?headers,
    };
    final encodedBody = body != null && body is! String
        ? jsonEncode(body)
        : body;

    try {
      final res = await _client
          .delete(uri, headers: effectiveHeaders, body: encodedBody)
          .timeout(timeout ?? _config.timeout);
      _checkResponse(res);
      return res;
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        'Tiempo de espera agotado al conectar con el servidor.',
      );
    }
  }

  /// Valida que el código de estado sea exitoso (2xx). Si es de error (4xx/5xx),
  /// arroja la excepción tipada correspondiente con el mensaje del servidor.
  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw ApiException.fromResponse(response.statusCode, response.body);
  }
}
