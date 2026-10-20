import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../application/session/session_controller.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'authenticated_client.dart';

/// Proveedor y gestor centralizado del cliente HTTP autenticado.
///
/// Vincula el ciclo de vida del token JWT administrado por [SessionController]
/// con las peticiones dirigidas al API Gateway (ASP.NET Core / YARP).
/// Provee instancias compartidas de [AuthenticatedClient] y [ApiClient]
/// para que los datasources no requieran instanciar clientes HTTP huérfanos.
class ApiClientProvider {
  ApiClientProvider._();

  static SessionController? _session;
  static AuthenticatedClient? _defaultClient;
  static ApiClient? _apiClient;
  static ApiConfig _config = ApiConfig();

  /// Inicializa el proveedor con la sesión activa y configuración opcional.
  static void initialize(
    SessionController session, {
    http.Client? innerClient,
    ApiConfig? config,
  }) {
    _session = session;
    if (config != null) _config = config;
    _defaultClient = create(session, innerClient: innerClient, config: _config);
    _apiClient = ApiClient(client: _defaultClient, config: _config);
  }

  /// Crea un [AuthenticatedClient] configurado para inyectar automáticamente
  /// el token actual de [session] y revocar la sesión ante respuestas 401.
  static AuthenticatedClient create(
    SessionController session, {
    http.Client? innerClient,
    ApiConfig? config,
  }) {
    return AuthenticatedClient(
      innerClient: innerClient,
      tokenProvider: () => session.token,
      onUnauthorized: () => session.signOut().catchError((Object _) {}),
      defaultTimeout: config?.timeout,
    );
  }

  /// Cliente HTTP predeterminado con autenticación JWT, timeouts y headers configurados.
  static AuthenticatedClient get defaultClient {
    if (_defaultClient == null) {
      final session = _session ?? SessionController();
      _defaultClient = create(session, config: _config);
      _session ??= session;
    }
    return _defaultClient!;
  }

  /// Cliente HTTP de alto nivel con métodos REST tipados y validación de errores.
  static ApiClient get apiClient {
    return _apiClient ??= ApiClient(client: defaultClient, config: _config);
  }

  /// Retorna la sesión asociada actual.
  static SessionController? get currentSession => _session;

  /// Restablece el cliente predeterminado (ideal para aislamiento en pruebas unitarias).
  @visibleForTesting
  static void reset({
    http.Client? mockClient,
    SessionController? session,
    ApiConfig? config,
  }) {
    _session = session;
    if (config != null) _config = config;
    if (mockClient is AuthenticatedClient) {
      _defaultClient = mockClient;
    } else if (mockClient != null) {
      _defaultClient = AuthenticatedClient(
        innerClient: mockClient,
        tokenProvider: () => _session?.token,
        onUnauthorized: () => _session?.signOut().catchError((Object _) {}),
      );
    } else {
      _defaultClient = null;
    }
    _apiClient = _defaultClient != null
        ? ApiClient(client: _defaultClient, config: _config)
        : null;
  }
}
