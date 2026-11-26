import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/config/oauth_config.dart';
import 'package:uct_map/data/repositories/oauth_pkce_repository.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/presentation/screens/login/login_page.dart';

OAuthConfig? oauthConfiguration({
  String provider = 'Ejemplo',
  String clientId = 'public-client',
  String authorization = 'https://identity.example/authorize',
  String token = 'https://identity.example/token',
  String redirect = 'cl.uct.app:/oauth/callback',
  String scopes = 'openid profile',
}) => OAuthConfig.fromValues(
  provider: provider,
  clientId: clientId,
  authorizationEndpoint: authorization,
  tokenEndpoint: token,
  redirectUri: redirect,
  scopes: scopes,
);

class StubOAuth implements OAuthRepository {
  int calls = 0;
  @override
  Future<AuthLoginResult?> signIn() async {
    calls++;
    throw StateError('La entrada externa debe permanecer oculta.');
  }
}

final config = OAuthConfig.fromValues(
  provider: 'Test provider',
  clientId: 'public-client',
  authorizationEndpoint: 'https://identity.example/authorize',
  tokenEndpoint: 'https://identity.example/token',
  redirectUri: 'cl.uct.app:/callback',
  scopes: 'profile',
)!;

Uri response(Uri authorization, {Map<String, String>? parameters}) =>
    config.redirectUri.replace(
      queryParameters:
          parameters ??
          {
            'code': 'one-use-code',
            'state': authorization.queryParameters['state']!,
          },
    );

void main() {
  group('Configuración OAuth', () {
    test('sin valores explícitos la configuración permanece ausente', () {
      expect(OAuthConfig.fromEnvironment(), isNull);
      expect(
        oauthConfiguration(
          provider: '',
          clientId: '',
          authorization: '',
          token: '',
          redirect: '',
          scopes: '',
        ),
        isNull,
      );
    });

    test('conserva las URL y scopes públicos del proveedor configurado', () {
      final actual = oauthConfiguration(scopes: 'openid   profile')!;
      expect(actual.provider, 'Ejemplo');
      expect(actual.clientId, 'public-client');
      expect(
        actual.authorizationEndpoint.toString(),
        'https://identity.example/authorize',
      );
      expect(actual.tokenEndpoint.toString(), 'https://identity.example/token');
      expect(actual.redirectUri.toString(), 'cl.uct.app:/oauth/callback');
      expect(actual.scopes, ['openid', 'profile']);
      expect(() => actual.scopes.add('other'), throwsUnsupportedError);
    });

    test('no acepta ajustes parciales ni endpoints HTTP públicos', () {
      expect(() => oauthConfiguration(token: ''), throwsFormatException);
      expect(
        () => oauthConfiguration(
          authorization: 'http://identity.example/authorize',
        ),
        throwsFormatException,
      );
      expect(
        () => oauthConfiguration(token: 'https://user@identity.example/token'),
        throwsFormatException,
      );
    });

    test(
      'acepta loopback para desarrollo y rechaza redirecciones inseguras',
      () {
        expect(
          oauthConfiguration(
            authorization: 'http://localhost:43123/authorize',
            token: 'http://127.0.0.1:43124/token',
            redirect: 'http://localhost:43125/callback',
          ),
          isNotNull,
        );
        expect(
          () =>
              oauthConfiguration(redirect: 'http://identity.example/callback'),
          throwsFormatException,
        );
        expect(
          () => oauthConfiguration(
            redirect: 'https://identity.example/callback#fragment',
          ),
          throwsFormatException,
        );
        expect(
          () => oauthConfiguration(redirect: 'callback'),
          throwsFormatException,
        );
      },
    );
  });

  group('Entrada OAuth', () {
    for (final configured in [false, true]) {
      testWidgets('OAuth oculto con repositorio configurado: $configured', (
        tester,
      ) async {
        final oauth = StubOAuth();
        await tester.pumpWidget(
          MaterialApp(
            home: LoginPage(oauthRepository: configured ? oauth : null),
          ),
        );
        expect(find.text('Continuar con cuenta externa'), findsNothing);
        expect(find.text('Acceso externo aún no disponible.'), findsNothing);
        expect(
          find.widgetWithText(ElevatedButton, 'Iniciar Sesión'),
          findsOneWidget,
        );
        expect(find.widgetWithText(ElevatedButton, 'Volver'), findsOneWidget);
        expect(oauth.calls, 0);
      });
    }
    testWidgets('login estrecho al 200 % conserva controles sin desbordar', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const LoginPage(),
        ),
      );
      await tester.ensureVisible(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Flujo PKCE', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    test(
      'Android opens external browser and handles platform cancellation',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        const channel = MethodChannel('flutter_web_auth_2');
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        addTearDown(() {
          debugDefaultTargetPlatformOverride = null;
          messenger.setMockMethodCallHandler(channel, null);
        });
        for (final cancel in [false, true]) {
          messenger.setMockMethodCallHandler(channel, (call) async {
            if (call.method != 'authenticate') return null;
            if (cancel) throw PlatformException(code: 'CANCELED');
            final arguments = call.arguments as Map;
            expect(arguments['callbackUrlScheme'], config.redirectUri.scheme);
            expect((arguments['options'] as Map)['useWebview'], false);
            return response(Uri.parse(arguments['url'] as String)).toString();
          });
          final client = OAuthPkceClient(
            config: config,
            httpClientFactory: () => MockClient(
              (_) async => http.Response(
                '{"access_token":"external","token_type":"Bearer"}',
                200,
                headers: {'content-type': 'application/json'},
              ),
            ),
          );
          expect(
            (await client.authorize())?.accessToken,
            cancel ? isNull : 'external',
          );
        }
      },
    );
    test(
      'uses library PKCE S256 and a public client without a secret',
      () async {
        final states = <String>{};
        final challenges = <String>{};
        final client = OAuthPkceClient(
          config: config,
          browser: (authorization, redirect) async {
            final query = authorization.queryParameters;
            expect(query['response_type'], 'code');
            expect(query['code_challenge_method'], 'S256');
            expect(query['code_challenge'], hasLength(43));
            expect(query['redirect_uri'], config.redirectUri.toString());
            expect(query['scope'], 'profile');
            states.add(query['state']!);
            challenges.add(query['code_challenge']!);
            return response(authorization);
          },
          httpClientFactory: () => MockClient((request) async {
            expect(request.url, config.tokenEndpoint);
            expect(request.followRedirects, false);
            final body = Uri.splitQueryString(request.body);
            expect(body['grant_type'], 'authorization_code');
            expect(body['code'], 'one-use-code');
            expect(body['client_id'], 'public-client');
            expect(body['code_verifier'], hasLength(128));
            expect(body.containsKey('client_secret'), isFalse);
            expect(request.headers.containsKey('authorization'), isFalse);
            return http.Response(
              jsonEncode({
                'access_token': 'external-access-token',
                'token_type': 'Bearer',
                'expires_in': 600,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        expect(
          (await client.authorize())?.accessToken,
          'external-access-token',
        );
        await client.authorize();
        expect(states, hasLength(2));
        expect(challenges, hasLength(2));
      },
    );

    for (final invalid in [
      'state',
      'missing-state',
      'duplicate',
      'path',
      'scheme',
      'authority',
      'fragment',
      'empty-code',
    ]) {
      test('rejects $invalid before contacting the token endpoint', () async {
        var requests = 0;
        final client = OAuthPkceClient(
          config: config,
          browser: (authorization, _) async {
            final valid = response(authorization);
            return switch (invalid) {
              'state' => response(
                authorization,
                parameters: {'code': 'x', 'state': 'wrong'},
              ),
              'missing-state' => response(
                authorization,
                parameters: {'code': 'x'},
              ),
              'duplicate' => Uri.parse('$valid&state=other'),
              'path' => valid.replace(path: '/unexpected'),
              'scheme' => valid.replace(scheme: 'other.app'),
              'authority' => Uri.parse(
                valid.toString().replaceFirst(':/', ':///'),
              ),
              'fragment' => valid.replace(fragment: 'unexpected'),
              _ => response(
                authorization,
                parameters: {
                  'code': '',
                  'state': authorization.queryParameters['state']!,
                },
              ),
            };
          },
          httpClientFactory: () => MockClient((_) async {
            requests++;
            return http.Response('', 500);
          }),
        );
        await expectLater(client.authorize(), throwsA(isA<AuthFailure>()));
        expect(requests, 0);
      });
    }

    test(
      'cancellation and access_denied create no session or token request',
      () async {
        for (final deny in [false, true]) {
          final client = OAuthPkceClient(
            config: config,
            browser: (authorization, _) async => deny
                ? response(
                    authorization,
                    parameters: {
                      'error': 'access_denied',
                      'state': authorization.queryParameters['state']!,
                    },
                  )
                : null,
            httpClientFactory: () => MockClient(
              (_) async => throw StateError('Must not request token'),
            ),
          );
          expect(await client.authorize(), isNull);
        }
      },
    );

    test(
      'sanitizes transport, timeout, invalid and rejected token errors',
      () async {
        for (final mode in ['network', 'timeout', 'invalid', 'rejected']) {
          final client = OAuthPkceClient(
            config: config,
            browser: (authorization, _) async => response(authorization),
            tokenTimeout: const Duration(milliseconds: 5),
            httpClientFactory: () => MockClient((_) async {
              if (mode == 'network') {
                throw http.ClientException('sensitive-provider-data');
              }
              if (mode == 'timeout') return Completer<http.Response>().future;
              if (mode == 'invalid') return http.Response('{}', 200);
              return http.Response(
                '{"error":"invalid_grant","error_description":"sensitive-provider-data"}',
                400,
                headers: {'content-type': 'application/json'},
              );
            }),
          );
          await expectLater(
            client.authorize(),
            throwsA(
              isA<AuthFailure>().having(
                (failure) =>
                    failure.message.contains('sensitive-provider-data'),
                'sanitized',
                false,
              ),
            ),
          );
        }
      },
    );

    test(
      'rejects overlapping authorization and allows retry after cancel',
      () async {
        final callback = Completer<Uri?>();
        final client = OAuthPkceClient(
          config: config,
          browser: (_, _) => callback.future,
        );
        final pending = client.authorize();
        await expectLater(client.authorize(), throwsA(isA<AuthFailure>()));
        callback.complete(null);
        expect(await pending, isNull);
        expect(await client.authorize(), isNull);
      },
    );

    test('session bridge explicitly receives credentials and returns existing result', () async {
      final client = OAuthPkceClient(
        config: config,
        browser: (authorization, _) async => response(authorization),
        httpClientFactory: () => MockClient(
          (_) async => http.Response(
            '{"access_token":"external","token_type":"Bearer"}',
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      final repository = OAuthPkceRepository(
        client: client,
        exchangeSession: (credentials) async {
          expect(credentials.accessToken, 'external');
          return const AuthLoginResult(
            userId: 'user',
            email: 'user@uct.cl',
            token: 'identity-session',
          );
        },
      );
      expect((await repository.signIn())?.token, 'identity-session');
    });
  });
}
