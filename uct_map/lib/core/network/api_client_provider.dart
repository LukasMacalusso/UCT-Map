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

  /// Sesión compartida: todas las pantallas usan la misma sesión y el mismo
  /// token, de modo que un cierre o un 401 afecta a toda la aplicación.
  static SessionController get session => _session ??= SessionController();

  /// Inicializa el proveedor con la sesión activa y configuración opcional.
  /// Reutiliza el cliente ya creado si la sesión no cambió.
  static void initialize(
    SessionController session, {
    http.Client? innerClient,
    ApiConfig? config,
  }) {
    if (config != null) _config = config;
    final rebuild =
        _session != session || innerClient != null || _defaultClient == null;
    _session = session;
    if (rebuild) {
      _defaultClient = create(session, innerClient: innerClient, config: _config);
      _apiClient = ApiClient(client: _defaultClient, config: _config);
    }
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
      onUnauthorized: session.handleUnauthorized,
      defaultTimeout: config?.timeout,
    );
  }

  /// Cliente HTTP predeterminado con autenticación JWT, timeouts y headers configurados.
  static AuthenticatedClient get defaultClient =>
      _defaultClient ??= create(session, config: _config);

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
        onUnauthorized: (token) => _session?.handleUnauthorized(token),
      );
    } else {
      _defaultClient = null;
    }
    _apiClient = _defaultClient != null
        ? ApiClient(client: _defaultClient, config: _config)
        : null;
  }
}
