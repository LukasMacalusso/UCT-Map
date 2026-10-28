import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Gestor centralizado de variables de entorno y configuración de APIs.
///
/// Lee las variables definidas en el archivo `.env` mediante `flutter_dotenv`
/// y provee valores por defecto seguros para desarrollo local, emuladores y pruebas automatizadas.
class EnvConfig {
  EnvConfig._();

  static bool _initialized = false;

  /// Inicializa la lectura del archivo `.env`.
  /// Si el archivo no existe o ocurre un error durante su lectura (por ejemplo en tests unitarios),
  /// no detiene la ejecución y utiliza los valores por defecto.
  static Future<void> init({String fileName = '.env'}) async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: fileName, isOptional: true);
      _initialized = true;
      if (kDebugMode) {
        debugPrint(
          '[EnvConfig] Variables cargadas desde $fileName (Ambiente: $appEnv, API: $apiBaseUrl)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[EnvConfig] No se pudo cargar $fileName, utilizando configuración por defecto. Detalle: $e',
        );
      }
    }
  }

  /// Inicializa con valores en memoria, ideal para pruebas unitarias.
  @visibleForTesting
  static void testInit(Map<String, String> values) {
    dotenv.loadFromString(mergeWith: values, isOptional: true);
    _initialized = true;
  }

  /// Limpia la configuración cargada (útil para teardown de pruebas).
  @visibleForTesting
  static void reset() {
    dotenv.clean();
    _initialized = false;
  }

  /// Obtiene un valor de forma segura, verificando si dotenv fue inicializado.
  static String? _get(String key) {
    if (!dotenv.isInitialized) return null;
    final val = dotenv.maybeGet(key);
    if (val == null || val.trim().isEmpty) return null;
    return val.trim();
  }

  /// Entorno de ejecución (`development`, `staging`, `production`).
  static String get appEnv =>
      _get('APP_ENV') ??
      const String.fromEnvironment('APP_ENV', defaultValue: 'development');

  /// URL Base del API Gateway o backend principal.
  static String get apiBaseUrl =>
      _get('API_BASE_URL') ??
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5000',
      );

  /// Tiempo límite de peticiones HTTP en segundos.
  static int get apiTimeoutSeconds {
    final raw = _get('API_TIMEOUT_SECONDS');
    if (raw != null) {
      final parsed = int.tryParse(raw);
      if (parsed != null && parsed > 0) return parsed;
    }
    return const int.fromEnvironment('API_TIMEOUT_SECONDS', defaultValue: 15);
  }

  /// [Duration] correspondiente a [apiTimeoutSeconds].
  static Duration get apiTimeout => Duration(seconds: apiTimeoutSeconds);

  /// Emisor esperado en los tokens (Identity).
  static String get jwtIssuer =>
      _get('JWT_ISSUER') ??
      const String.fromEnvironment(
        'JWT_ISSUER',
        defaultValue: 'https://identity-api',
      );

  /// Audiencia esperada en los tokens (API Gateway).
  static String get jwtAudience =>
      _get('JWT_AUDIENCE') ??
      const String.fromEnvironment(
        'JWT_AUDIENCE',
        defaultValue: 'api-gateway',
      );

  /// Clave de API opcional para autenticación contra Gateway o servicios externos.
  static String get apiKey =>
      _get('API_KEY') ??
      const String.fromEnvironment('API_KEY', defaultValue: '');

  /// Secreto de API opcional.
  static String get apiSecret =>
      _get('API_SECRET') ??
      const String.fromEnvironment('API_SECRET', defaultValue: '');

  /// URL directa para el microservicio de Identity (opcional, en caso de bypass del Gateway).
  static String? get identityServiceUrl => _get('IDENTITY_SERVICE_URL');

  /// URL directa para el microservicio de Campus (opcional).
  static String? get campusServiceUrl => _get('CAMPUS_SERVICE_URL');

  /// URL directa para el microservicio de Schedule (opcional).
  static String? get scheduleServiceUrl => _get('SCHEDULE_SERVICE_URL');

  /// URL directa para el microservicio de Incident (opcional).
  static String? get incidentServiceUrl => _get('INCIDENT_SERVICE_URL');

  /// Plantilla de URL para capas de teselas del mapa (OpenStreetMap o servidor de teselas institucional).
  static String get mapTileUrl =>
      _get('MAP_TILE_URL') ??
      const String.fromEnvironment(
        'MAP_TILE_URL',
        defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
}
