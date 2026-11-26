import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_config.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/core/network/authenticated_client.dart';

const _testOrigin = 'https://gateway.invalid';
const _testResource = '/test-resource';

void main() {
  group('ApiConfig & ApiEndpoints Tests', () {
    test('Combina las rutas configuradas con un origen de prueba', () {
      final config = ApiConfig(baseUrl: _testOrigin);
      for (final path in [
        ApiEndpoints.identityLogin,
        ApiEndpoints.campusList,
        ApiEndpoints.scheduleMeetings,
        ApiEndpoints.incidentLostObjects,
      ]) {
        final uri = config.uri(path);
        expect(uri.origin, _testOrigin);
        expect(uri.path, path);
      }

      final buildings = config.uri(ApiEndpoints.campusBuildings('c-1'));
      expect(buildings.path, ApiEndpoints.campusBuildingsList);
      expect(buildings.queryParameters, {'campusId': 'c-1'});

      final reports = config.uri(ApiEndpoints.incidentReports, {
        'campus': 'San Francisco',
      });
      expect(reports.path, ApiEndpoints.incidentReports);
      expect(reports.queryParameters, {'campus': 'San Francisco'});
      expect(reports.query, 'campus=San+Francisco');
    });
  });

  group('AuthenticatedClient Tests', () {
    test(
      'Inyecta header Authorization: Bearer cuando el token existe',
      () async {
        String? capturedAuthHeader;

        final mockInner = MockClient((request) async {
          capturedAuthHeader = request.headers['Authorization'];
          return http.Response('{"ok": true}', 200);
        });

        final client = AuthenticatedClient(
          innerClient: mockInner,
          tokenProvider: () => 'jwt-test-token-123',
          enableLogging: false,
        );

        final response = await client.get(
          Uri.parse('$_testOrigin$_testResource'),
        );

        expect(response.statusCode, 200);
        expect(capturedAuthHeader, 'Bearer jwt-test-token-123');
      },
    );

    test(
      'Inyecta headers estándar Accept, User-Agent, Content-Type y X-Api-Key',
      () async {
        Map<String, String>? capturedHeaders;

        final mockInner = MockClient((request) async {
          capturedHeaders = request.headers;
          return http.Response('{"status": "created"}', 201);
        });

        final client = AuthenticatedClient(
          innerClient: mockInner,
          apiKeyProvider: () => 'my-custom-key',
          enableLogging: false,
        );

        final response = await client.post(
          Uri.parse('$_testOrigin$_testResource'),
          body: jsonEncode({'title': 'Incidente'}),
        );

        expect(response.statusCode, 201);
        expect(capturedHeaders?['Accept'], 'application/json');
        expect(capturedHeaders?['User-Agent'], contains('UCT-Map'));
        expect(capturedHeaders?['X-Api-Key'], 'my-custom-key');
        expect(capturedHeaders?['Content-Type'], contains('application/json'));
      },
    );

    for (final (label, status, isLogin, header, sent, notifications) in [
      (
        '401 con Bearer inyectado',
        401,
        false,
        null,
        'Bearer current-token',
        ['current-token'],
      ),
      (
        '401 con Bearer explícito',
        401,
        false,
        'Bearer previous-token',
        'Bearer previous-token',
        ['previous-token'],
      ),
      (
        '401 con otro esquema',
        401,
        false,
        'Basic test-credentials',
        'Basic test-credentials',
        <String?>[null],
      ),
      ('401 al iniciar sesión', 401, true, null, null, <String?>[]),
      ('403 con sesión', 403, false, null, 'Bearer current-token', <String?>[]),
      ('409 con sesión', 409, false, null, 'Bearer current-token', <String?>[]),
    ]) {
      test('$label asocia el rechazo a la credencial de la petición', () async {
        final rejectedTokens = <String?>[];
        final client = AuthenticatedClient(
          innerClient: MockClient((request) async {
            expect(request.headers['Authorization'], sent);
            return http.Response('{}', status);
          }),
          tokenProvider: () => 'current-token',
          onUnauthorized: rejectedTokens.add,
          enableLogging: false,
        );
        addTearDown(client.close);
        final request = http.Request(
          isLogin ? 'POST' : 'GET',
          ApiConfig(baseUrl: _testOrigin)
              .uri(isLogin ? ApiEndpoints.identityLogin : _testResource),
        );
        if (header != null) request.headers['Authorization'] = header;

        final response = await client.send(request);

        expect(response.statusCode, status);
        expect(rejectedTokens, notifications);
      });
    }
  });

  group('ApiClient High-Level Client Tests', () {
    test('get y getJson decodifican exitosamente respuesta 200', () async {
      final mockInner = MockClient((request) async {
        if (request.url.path == ApiEndpoints.campusList) {
          return http.Response(
            jsonEncode([
              {'id': 'c-1', 'name': 'Campus San Francisco'},
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        client: mockInner,
        config: ApiConfig(baseUrl: _testOrigin),
      );

      final list = await apiClient.getJson<List<dynamic>>(
        ApiEndpoints.campusList,
      );
      expect(list.length, 1);
      expect(list[0]['name'], 'Campus San Francisco');
    });

    test('post y postJson serializan body y retornan objeto tipado', () async {
      String? sentBody;

      final mockInner = MockClient((request) async {
        sentBody = request.body;
        return http.Response(
          jsonEncode({'id': 'ticket-99', 'status': 'Pending'}),
          201,
        );
      });

      final apiClient = ApiClient(
        client: mockInner,
        config: ApiConfig(baseUrl: _testOrigin),
      );

      final result = await apiClient.postJson<Map<String, dynamic>>(
        ApiEndpoints.incidentReports,
        body: {'title': 'Vidrio roto', 'location': 'Edificio A'},
      );

      expect(sentBody, contains('Vidrio roto'));
      expect(result['id'], 'ticket-99');
    });

    test('patch y delete ejecutan peticiones hacia el API Gateway', () async {
      String? patchMethod;
      String? deleteMethod;

      final mockInner = MockClient((request) async {
        if (request.method == 'PATCH') {
          patchMethod = request.method;
          return http.Response('', 204);
        }
        if (request.method == 'DELETE') {
          deleteMethod = request.method;
          return http.Response('', 200);
        }
        return http.Response('', 400);
      });

      final apiClient = ApiClient(
        client: mockInner,
        config: ApiConfig(baseUrl: _testOrigin),
      );

      final patchRes = await apiClient.patch(
        ApiEndpoints.meetingStatus('m-1'),
        body: {'status': 'Confirmed'},
      );
      expect(patchRes.statusCode, 204);
      expect(patchMethod, 'PATCH');

      final deleteRes = await apiClient.delete(
        ApiEndpoints.incidentReportDetail('r-1'),
      );
      expect(deleteRes.statusCode, 200);
      expect(deleteMethod, 'DELETE');
    });

    test('Lanza ApiException cuando el Gateway retorna error >= 400', () async {
      final mockInner = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
            'title': 'Email and password are required.',
            'status': 400,
          }),
          400,
        );
      });

      final apiClient = ApiClient(
        client: mockInner,
        config: ApiConfig(baseUrl: _testOrigin),
      );

      expect(
        () => apiClient.post(ApiEndpoints.identityLogin, body: {}),
        throwsA(
          isA<BadRequestException>().having(
            (e) => e.message,
            'message',
            contains('Email and password are required.'),
          ),
        ),
      );
    });
  });

  group('ApiException Hierarchy & ProblemDetails Parsing Tests', () {
    for (final (status, expected) in [
      (400, isA<BadRequestException>()),
      (401, isA<UnauthorizedException>()),
      (403, isA<ForbiddenException>()),
      (404, isA<NotFoundException>()),
      (409, isA<ConflictException>()),
      (500, isA<ServerException>()),
    ]) {
      test('HTTP $status conserva su tipo y código de error', () {
        final error = ApiException.fromResponse(status, '{}');
        expect(error, expected);
        expect(error.statusCode, status);
      });
    }

    test('un error de red conserva su mensaje', () {
      const error = NetworkException('Sin conexión');
      expect(error.message, 'Sin conexión');
    });

    test(
      'Parsea ProblemDetails RFC 7807 de ASP.NET Core con title y detail',
      () {
        const jsonBody = '''
      {
        "type": "https://tools.ietf.org/html/rfc9110#section-15.5.5",
        "title": "Recurso no encontrado",
        "status": 404,
        "detail": "El profesor con id prof-99 no existe en el sistema."
      }
      ''';

        final ex = ApiException.fromResponse(404, jsonBody);
        expect(ex, isA<NotFoundException>());
        expect(
          ex.message,
          'El profesor con id prof-99 no existe en el sistema.',
        );
      },
    );

    test(
      'Parsea ProblemDetails con diccionario errors (validación de ModelState)',
      () {
        const jsonBody = '''
      {
        "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
        "title": "One or more validation errors occurred.",
        "status": 400,
        "errors": {
          "Email": ["The Email field is required."],
          "Password": ["Password must be at least 6 characters."]
        }
      }
      ''';

        final ex = ApiException.fromResponse(400, jsonBody);
        expect(ex, isA<BadRequestException>());
        expect(ex.message, contains('The Email field is required.'));
        expect(ex.message, contains('Password must be at least 6 characters.'));
      },
    );

    test('Parsea respuesta string plana en BadRequest', () {
      final ex = ApiException.fromResponse(
        400,
        'Email and password are required.',
      );
      expect(ex, isA<BadRequestException>());
      expect(ex.message, 'Email and password are required.');
    });
  });

  group('ApiClientProvider Tests', () {
    test('Configura e inicializa cliente compartido con sesión', () {
      final session = SessionController();
      ApiClientProvider.initialize(session);

      expect(ApiClientProvider.currentSession, equals(session));
      expect(ApiClientProvider.defaultClient, isNotNull);
      expect(ApiClientProvider.apiClient, isNotNull);
    });

    test('Permite restablecer cliente con MockClient para pruebas', () async {
      String? requestedPath;
      final mock = MockClient((req) async {
        requestedPath = req.url.path;
        return http.Response('{"ok": true}', 200);
      });

      ApiClientProvider.reset(mockClient: mock);

      final res = await ApiClientProvider.defaultClient.get(
        Uri.parse('$_testOrigin$_testResource'),
      );
      expect(res.statusCode, 200);
      expect(requestedPath, _testResource);

      ApiClientProvider.reset();
    });
  });
}
