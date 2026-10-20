import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

typedef TokenProvider = String? Function();
typedef ApiKeyProvider = String? Function();

/// Recibe el token con el que se hizo la petición rechazada.
typedef UnauthorizedHandler = void Function(String? token);

/// Cliente HTTP configurado para la comunicación con el API Gateway y microservicios.
///
/// Características:
/// - Inyección automática de token JWT Bearer (`Authorization: Bearer <token>`).
/// - Inyección de clave de API (`X-Api-Key: <apiKey>`) configurada en `.env`.
/// - Encabezados estándar por defecto (`Accept: application/json`, `User-Agent`, `Content-Type`).
/// - Manejo centralizado de timeouts desde `EnvConfig.apiTimeout`.
/// - Detección y notificación automática de 401 Unauthorized para revocar sesiones expiradas.
/// - Registro detallado de peticiones y latencia en `kDebugMode`.
class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({
    http.Client? innerClient,
    this.tokenProvider,
    this.apiKeyProvider,
    this.onUnauthorized,
    this.defaultTimeout,
    this.enableLogging = kDebugMode,
  }) : _inner = innerClient ?? http.Client();

  final http.Client _inner;
  final TokenProvider? tokenProvider;
  final ApiKeyProvider? apiKeyProvider;
  final UnauthorizedHandler? onUnauthorized;
  final Duration? defaultTimeout;
  final bool enableLogging;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Inyectar Token Bearer si está disponible y no se configuró manualmente
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty && !request.headers.containsKey('Authorization')) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // 2. Inyectar ApiKey si está configurada
    final key = apiKeyProvider?.call() ?? EnvConfig.apiKey;
    if (key.isNotEmpty && !request.headers.containsKey('X-Api-Key')) {
      request.headers['X-Api-Key'] = key;
    }

    // 3. Encabezados de contenido y negociación
    if (!request.headers.containsKey('Accept')) {
      request.headers['Accept'] = 'application/json';
    }
    if (!request.headers.containsKey('User-Agent')) {
      request.headers['User-Agent'] = 'UCT-Map/1.0 (Flutter; Mobile)';
    }
    final currentContentType = request.headers['content-type'];
    if (currentContentType == null || currentContentType.startsWith('text/plain')) {
      if (request is http.Request && request.body.isNotEmpty) {
        request.headers['content-type'] = 'application/json; charset=utf-8';
      }
    }

    final effectiveTimeout = defaultTimeout ?? EnvConfig.apiTimeout;
    final sw = Stopwatch()..start();

    if (enableLogging) {
      debugPrint('[HTTP] --> ${request.method} ${request.url}');
    }

    try {
      final response = await _inner.send(request).timeout(effectiveTimeout);
      sw.stop();

      if (enableLogging) {
        debugPrint(
          '[HTTP] <-- ${response.statusCode} ${request.method} ${request.url} (${sw.elapsedMilliseconds}ms)',
        );
      }

      // Si el Gateway retorna 401 Unauthorized, notificar para revocar sesión
      if (response.statusCode == 401) {
        onUnauthorized?.call(token);
      }

      return response;
    } catch (e) {
      sw.stop();
      if (enableLogging) {
        debugPrint(
          '[HTTP] xxx ${request.method} ${request.url} FAILED (${sw.elapsedMilliseconds}ms): $e',
        );
      }
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
