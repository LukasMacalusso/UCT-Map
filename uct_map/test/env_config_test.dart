import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/core/config/env_config.dart';
import 'package:uct_map/core/network/api_config.dart';
import 'package:uct_map/core/network/api_endpoints.dart';

void main() {
  group('EnvConfig Tests', () {
    tearDown(() {
      EnvConfig.reset();
    });

    test('Valores por defecto cuando no se han inyectado variables', () {
      EnvConfig.reset();

      expect(EnvConfig.appEnv, 'development');
      expect(EnvConfig.apiBaseUrl, 'http://localhost:5000');
      expect(EnvConfig.apiTimeoutSeconds, 15);
      expect(EnvConfig.apiTimeout, const Duration(seconds: 15));
      expect(EnvConfig.apiKey, isEmpty);
      expect(EnvConfig.identityServiceUrl, isNull);
      expect(EnvConfig.mapTileUrl, contains('tile.openstreetmap.org'));
    });

    test('Carga y lee variables personalizadas desde entorno simulado', () {
      EnvConfig.testInit({
        'APP_ENV': 'production',
        'API_BASE_URL': 'https://api.uct.cl/gateway',
        'API_TIMEOUT_SECONDS': '30',
        'API_KEY': 'secret-prod-key-xyz',
        'API_SECRET': 'super-secret-token',
        'IDENTITY_SERVICE_URL': 'https://auth.uct.cl',
        'MAP_TILE_URL': 'https://tiles.uct.cl/{z}/{x}/{y}.png',
      });

      expect(EnvConfig.appEnv, 'production');
      expect(EnvConfig.apiBaseUrl, 'https://api.uct.cl/gateway');
      expect(EnvConfig.apiTimeoutSeconds, 30);
      expect(EnvConfig.apiTimeout, const Duration(seconds: 30));
      expect(EnvConfig.apiKey, 'secret-prod-key-xyz');
      expect(EnvConfig.apiSecret, 'super-secret-token');
      expect(EnvConfig.identityServiceUrl, 'https://auth.uct.cl');
      expect(EnvConfig.mapTileUrl, 'https://tiles.uct.cl/{z}/{x}/{y}.png');
    });

    test('ApiConfig hereda automáticamente los valores de EnvConfig', () {
      EnvConfig.testInit({
        'API_BASE_URL': 'http://10.0.2.2:5052',
        'API_TIMEOUT_SECONDS': '25',
        'API_KEY': 'api-emulator-key',
      });

      final config = ApiConfig();

      expect(config.baseUrl, 'http://10.0.2.2:5052');
      expect(config.timeout, const Duration(seconds: 25));
      expect(config.apiKey, 'api-emulator-key');

      // Verifica resolución de URI hacia el Gateway configurado
      expect(
        config.uri(ApiEndpoints.identityLogin).toString(),
        'http://10.0.2.2:5052/api/identity/login',
      );
    });

    test('ApiConfig permite sobreescribir valores explícitamente', () {
      EnvConfig.testInit({
        'API_BASE_URL': 'http://localhost:5052',
      });

      final customConfig = ApiConfig(
        baseUrl: 'https://staging.uct.cl',
        timeout: const Duration(seconds: 5),
        apiKey: 'custom-key',
      );

      expect(customConfig.baseUrl, 'https://staging.uct.cl');
      expect(customConfig.timeout, const Duration(seconds: 5));
      expect(customConfig.apiKey, 'custom-key');
    });
  });
}
