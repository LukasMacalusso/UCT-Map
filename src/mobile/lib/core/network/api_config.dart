import '../config/env_config.dart';
import 'api_endpoints.dart';

// URL base del API Gateway y rutas del backend cargadas desde .env.
class ApiConfig {
  ApiConfig({String? baseUrl, Duration? timeout, String? apiKey})
    : baseUrl = baseUrl ?? EnvConfig.apiBaseUrl,
      timeout = timeout ?? EnvConfig.apiTimeout,
      apiKey = apiKey ?? EnvConfig.apiKey;

  static String get defaultBaseUrl => EnvConfig.apiBaseUrl;

  /// Host del Gateway visto desde un emulador Android.
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5000';

  static const String loginPath = ApiEndpoints.identityLogin;

  static Duration get defaultTimeout => EnvConfig.apiTimeout;

  final String baseUrl;
  final Duration timeout;
  final String apiKey;

  /// Retorna un objeto [Uri] completo a partir de una ruta del Gateway y parámetros opcionales.
  Uri uri(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$baseUrl$cleanPath';
    final baseUri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return baseUri;
    }
    final stringParams = queryParameters.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );
    return baseUri.replace(queryParameters: stringParams);
  }

  Uri get loginUri => uri(loginPath);
}
