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

void main() {
  group('ApiConfig & ApiEndpoints Tests', () {
    test('Resuelve URIs correctas para los 4 microservicios', () {
      final config = ApiConfig(baseUrl: 'http://localhost:5052');

      expect(
        config.uri(ApiEndpoints.identityLogin).toString(),
        'http://localhost:5052/api/identity/login',
      );
      expect(
        config.uri(ApiEndpoints.campusList).toString(),
        'http://localhost:5052/api/campus/campuses',
      );
      expect(
        config.uri(ApiEndpoints.campusBuildings('c-1')).toString(),
        'http://localhost:5052/api/campus/buildings?campusId=c-1',
      );
      expect(
        config.uri(ApiEndpoints.scheduleProfessors).toString(),
        'http://localhost:5052/api/schedule/professors',
      );
      expect(
        config.uri(ApiEndpoints.incidentLostItems).toString(),
        'http://localhost:5052/api/incident/lost-items',
      );
      expect(
        config.uri(ApiEndpoints.incidentReports, {'campus': 'San Francisco'}).toString(),
        'http://localhost:5052/api/incident/reports?campus=San+Francisco',
      );
    });
  });

  group('AuthenticatedClient Tests', () {
    test('Inyecta header Authorization: Bearer cuando el token existe', () async {
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

      final response = await client.get(Uri.parse('http://localhost:5052/api/campus'));

      expect(response.statusCode, 200);
      expect(capturedAuthHeader, 'Bearer jwt-test-token-123');
    });

    test('Inyecta headers estándar Accept, User-Agent, Content-Type y X-Api-Key', () async {
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
        Uri.parse('http://localhost:5052/api/incident/reports'),
        body: jsonEncode({'title': 'Incidente'}),
      );

      expect(response.statusCode, 201);
      expect(capturedHeaders?['Accept'], 'application/json');
      expect(capturedHeaders?['User-Agent'], contains('UCT-Map'));
      expect(capturedHeaders?['X-Api-Key'], 'my-custom-key');
      expect(capturedHeaders?['Content-Type'], contains('application/json'));
    });

    test('Llama a onUnauthorized cuando el Gateway devuelve 401', () async {
      bool unauthorizedCalled = false;

      final mockInner = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });

      final client = AuthenticatedClient(
        innerClient: mockInner,
        tokenProvider: () => 'expired-token',
        onUnauthorized: (_) {
          unauthorizedCalled = true;
        },
        enableLogging: false,
      );

      final response = await client.get(Uri.parse('http://localhost:5052/api/schedule/meetings'));

      expect(response.statusCode, 401);
      expect(unauthorizedCalled, isTrue);
    });
  });

  group('ApiClient High-Level Client Tests', () {
    test('get y getJson decodifican exitosamente respuesta 200', () async {
      final mockInner = MockClient((request) async {
        if (request.url.path.startsWith('/api/campus')) {
          return http.Response(
            jsonEncode([{'id': 'c-1', 'name': 'Campus San Francisco'}]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        client: mockInner,
        config: ApiConfig(baseUrl: 'http://localhost:5052'),
      );

      final list = await apiClient.getJson<List<dynamic>>(ApiEndpoints.campusList);
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
        config: ApiConfig(baseUrl: 'http://localhost:5052'),
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
        config: ApiConfig(baseUrl: 'http://localhost:5052'),
      );

      final patchRes = await apiClient.patch('/api/schedule/meetings/m-1/status', body: {'status': 'Confirmed'});
      expect(patchRes.statusCode, 204);
      expect(patchMethod, 'PATCH');

      final deleteRes = await apiClient.delete('/api/incident/reports/r-1');
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
        config: ApiConfig(baseUrl: 'http://localhost:5052'),
      );

      expect(
        () => apiClient.post(ApiEndpoints.identityLogin, body: {}),
        throwsA(isA<BadRequestException>().having(
          (e) => e.message,
          'message',
          contains('Email and password are required.'),
        )),
      );
    });
  });

  group('ApiException Hierarchy & ProblemDetails Parsing Tests', () {
    test('Verifica propiedades de excepciones tipadas', () {
      const badReq = BadRequestException('Datos inválidos');
      expect(badReq.statusCode, 400);

      const unauth = UnauthorizedException();
      expect(unauth.statusCode, 401);

      const forbidden = ForbiddenException();
      expect(forbidden.statusCode, 403);

      const notFound = NotFoundException();
      expect(notFound.statusCode, 404);

      const conflict = ConflictException();
      expect(conflict.statusCode, 409);

      const netErr = NetworkException('Sin conexión');
      expect(netErr.message, 'Sin conexión');

      const serverErr = ServerException();
      expect(serverErr.statusCode, 500);
    });

    test('Parsea ProblemDetails RFC 7807 de ASP.NET Core con title y detail', () {
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
      expect(ex.message, 'El profesor con id prof-99 no existe en el sistema.');
    });

    test('Parsea ProblemDetails con diccionario errors (validación de ModelState)', () {
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
    });

    test('Parsea respuesta string plana en BadRequest', () {
      final ex = ApiException.fromResponse(400, 'Email and password are required.');
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

      final res = await ApiClientProvider.defaultClient.get(Uri.parse('http://localhost:5052/api/campus'));
      expect(res.statusCode, 200);
      expect(requestedPath, '/api/campus');

      ApiClientProvider.reset();
    });
  });
}

