/// Public client settings; no client secret belongs in a mobile application.
class OAuthConfig {
  OAuthConfig._({
    required this.provider,
    required this.clientId,
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.redirectUri,
    required this.scopes,
  });

  final String provider;
  final String clientId;
  final Uri authorizationEndpoint;
  final Uri tokenEndpoint;
  final Uri redirectUri;
  final List<String> scopes;

  /// Returns null only when no OAuth settings have been supplied.
  static OAuthConfig? fromValues({
    required String provider,
    required String clientId,
    required String authorizationEndpoint,
    required String tokenEndpoint,
    required String redirectUri,
    String scopes = '',
  }) {
    final values = [
      provider,
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      redirectUri,
      scopes,
    ].map((value) => value.trim()).toList();
    if (values.every((value) => value.isEmpty)) return null;
    if (values.take(5).any((value) => value.isEmpty)) {
      throw const FormatException('Configuración OAuth incompleta.');
    }

    return OAuthConfig._(
      provider: values[0],
      clientId: values[1],
      authorizationEndpoint: _endpoint(values[2]),
      tokenEndpoint: _endpoint(values[3]),
      redirectUri: _redirect(values[4]),
      scopes: List.unmodifiable(
        values[5].isEmpty ? <String>[] : values[5].split(RegExp(r'\s+')),
      ),
    );
  }

  static OAuthConfig? fromEnvironment() => fromValues(
    provider: const String.fromEnvironment('OAUTH_PROVIDER'),
    clientId: const String.fromEnvironment('OAUTH_CLIENT_ID'),
    authorizationEndpoint: const String.fromEnvironment(
      'OAUTH_AUTHORIZATION_URL',
    ),
    tokenEndpoint: const String.fromEnvironment('OAUTH_TOKEN_URL'),
    redirectUri: const String.fromEnvironment('OAUTH_REDIRECT_URI'),
    scopes: const String.fromEnvironment('OAUTH_SCOPES'),
  );

  static Uri _endpoint(String value) {
    final uri = _parse(value);
    if (!uri.hasAuthority || uri.host.isEmpty || !_isSecureWebUri(uri)) {
      throw const FormatException('URL de OAuth inválida o insegura.');
    }
    return uri;
  }

  static Uri _redirect(String value) {
    final uri = _parse(value);
    final isWeb = uri.scheme == 'https' || uri.scheme == 'http';
    if (isWeb) {
      if (!uri.hasAuthority || uri.host.isEmpty || !_isSecureWebUri(uri)) {
        throw const FormatException('Redirección OAuth inválida o insegura.');
      }
    } else if (!uri.scheme.contains('.') ||
        (uri.host.isEmpty && uri.path.isEmpty)) {
      throw const FormatException('Redirección OAuth inválida.');
    }
    return uri;
  }

  static Uri _parse(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        value.contains(RegExp(r'\s'))) {
      throw const FormatException('URI OAuth inválida.');
    }
    return uri;
  }

  static bool _isSecureWebUri(Uri uri) =>
      uri.scheme == 'https' ||
      (uri.scheme == 'http' &&
          const {'localhost', '127.0.0.1', '::1'}.contains(uri.host));
}
