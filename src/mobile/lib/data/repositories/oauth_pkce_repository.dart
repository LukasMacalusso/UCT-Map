import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;

import '../../core/config/oauth_config.dart';
import '../../domain/repositories/auth_repository.dart';

typedef OAuthBrowser = Future<Uri?> Function(Uri authorization, Uri redirect);
typedef OAuthSessionExchange = Future<AuthLoginResult> Function(
  oauth2.Credentials credentials,
);

/// Authorization does not establish an Identity session by itself.
class OAuthPkceRepository implements OAuthRepository {
  OAuthPkceRepository({required this.client, required this.exchangeSession});

  final OAuthPkceClient client;
  final OAuthSessionExchange exchangeSession;
  bool _busy = false;

  @override
  Future<AuthLoginResult?> signIn() async {
    if (_busy) throw const AuthFailure('Ya hay un inicio de sesión en curso.');
    _busy = true;
    try {
      final credentials = await client.authorize();
      return credentials == null ? null : await exchangeSession(credentials);
    } finally {
      _busy = false;
    }
  }
}

class OAuthPkceClient {
  OAuthPkceClient({
    required this.config,
    OAuthBrowser? browser,
    http.Client Function()? httpClientFactory,
    this.tokenTimeout = const Duration(seconds: 20),
  }) : _browser = browser ?? _openBrowser,
       _httpClientFactory = httpClientFactory ?? http.Client.new;

  final OAuthConfig config;
  final OAuthBrowser _browser;
  final http.Client Function() _httpClientFactory;
  final Duration tokenTimeout;
  bool _busy = false;

  Future<oauth2.Credentials?> authorize() async {
    if (_busy) throw const AuthFailure('Ya hay un inicio de sesión en curso.');
    _busy = true;
    oauth2.AuthorizationCodeGrant? grant;
    try {
      final random = Random.secure();
      final state = base64Url.encode(
        List.generate(32, (_) => random.nextInt(256)),
      );
      grant = oauth2.AuthorizationCodeGrant(
        config.clientId,
        config.authorizationEndpoint,
        config.tokenEndpoint,
        httpClient: _TokenHttpClient(_httpClientFactory()),
      );
      final authorization = grant.getAuthorizationUrl(
        config.redirectUri,
        scopes: config.scopes,
        state: state,
      );
      final callback = await _browser(authorization, config.redirectUri);
      if (callback == null) return null;
      _validateCallback(callback);
      final parameters = callback.queryParameters;
      if (parameters['state'] != state ||
          (parameters['error'] == null &&
              (parameters['code']?.isEmpty ?? true))) {
        throw const FormatException('Invalid authorization response.');
      }
      final result = await grant
          .handleAuthorizationResponse(parameters)
          .timeout(tokenTimeout);
      if (result.credentials.accessToken.isEmpty ||
          result.credentials.isExpired) {
        throw const FormatException('Invalid credentials.');
      }
      return result.credentials;
    } on oauth2.AuthorizationException catch (error) {
      if (error.error == 'access_denied') return null;
      throw const AuthFailure('El proveedor rechazó el inicio de sesión.');
    } on TimeoutException {
      throw const AuthFailure(
        'El proveedor tardó demasiado. Intenta de nuevo.',
      );
    } on http.ClientException {
      throw const AuthFailure('No se pudo conectar con el proveedor.');
    } on FormatException {
      throw const AuthFailure('La respuesta del proveedor no es válida.');
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure('No se pudo completar el acceso externo.');
    } finally {
      grant?.close();
      _busy = false;
    }
  }

  void _validateCallback(Uri callback) {
    final registered = config.redirectUri;
    if (callback.scheme != registered.scheme ||
        callback.hasAuthority != registered.hasAuthority ||
        callback.userInfo != registered.userInfo ||
        callback.host != registered.host ||
        callback.port != registered.port ||
        callback.path != registered.path ||
        callback.hasFragment ||
        callback.queryParametersAll.values.any(
          (values) => values.length != 1,
        ) ||
        registered.queryParameters.entries.any(
          (entry) => callback.queryParameters[entry.key] != entry.value,
        )) {
      throw const FormatException('Unexpected redirect.');
    }
  }

  static Future<Uri?> _openBrowser(Uri authorization, Uri redirect) async {
    if (kIsWeb) {
      if (!redirect.hasAuthority || redirect.origin != Uri.base.origin) {
        throw const AuthFailure(
          'La redirección debe pertenecer a esta aplicación.',
        );
      }
    } else if (defaultTargetPlatform != TargetPlatform.android) {
      throw const AuthFailure(
        'El acceso externo está preparado para Android y Web.',
      );
    } else if (redirect.scheme == 'https' || redirect.scheme == 'http') {
      throw const AuthFailure(
        'Android requiere una redirección con esquema propio.',
      );
    }
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authorization.toString(),
        callbackUrlScheme: redirect.scheme,
        options: FlutterWebAuth2Options(
          useWebview: false,
          httpsHost: redirect.host,
          httpsPath: redirect.path,
          timeout: 300,
        ),
      );
      return Uri.parse(result);
    } on PlatformException catch (error) {
      if (error.code == 'CANCELED') return null;
      throw const AuthFailure(
        'No se pudo completar el acceso en el navegador.',
      );
    }
  }
}

class _TokenHttpClient extends http.BaseClient {
  _TokenHttpClient(this.inner);
  final http.Client inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Authorization codes and verifiers must not follow endpoint redirects.
    request.followRedirects = false;
    return inner.send(request);
  }

  @override
  void close() => inner.close();
}
