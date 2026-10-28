import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/core/network/problem_details.dart';
import 'package:uct_map/data/datasources/lost_objects_remote_ds.dart';
import 'package:uct_map/data/models/lost_object_dto.dart';
import 'package:uct_map/data/repositories/lost_objects_repository_impl.dart';
import 'package:uct_map/domain/entities/lost_object.dart';
import 'package:uct_map/domain/repositories/lost_objects_repository.dart';
import 'package:uct_map/presentation/screens/lost_objects/create_lost_object_screen.dart';
import 'package:uct_map/presentation/screens/lost_objects/lost_objects_screen.dart';
import 'package:uct_map/presentation/screens/lost_objects/widgets/lost_object_status_badge.dart';

void main() {
  group('LostObject & LostObjectStatus Models Tests', () {
    test('LostObjectStatus enum mapea correctamente valores enteros y labels', () {
      expect(LostObjectStatus.pending.value, 0);
      expect(LostObjectStatus.inProcess.value, 1);
      expect(LostObjectStatus.resolved.value, 2);
      expect(LostObjectStatus.canceled.value, 3);

      expect(LostObjectStatus.pending.apiName, 'Pending');
      expect(LostObjectStatus.inProcess.apiName, 'In_Process');
      expect(LostObjectStatus.resolved.apiName, 'Resolved');
      expect(LostObjectStatus.canceled.apiName, 'Canceled');

      // Parsea desde enteros
      expect(LostObjectStatus.fromValue(0), LostObjectStatus.pending);
      expect(LostObjectStatus.fromValue(1), LostObjectStatus.inProcess);
      expect(LostObjectStatus.fromValue(2), LostObjectStatus.resolved);
      expect(LostObjectStatus.fromValue(3), LostObjectStatus.canceled);

      // Parsea desde strings
      expect(LostObjectStatus.fromValue('Pending'), LostObjectStatus.pending);
      expect(LostObjectStatus.fromValue('In_Process'), LostObjectStatus.inProcess);
      expect(LostObjectStatus.fromValue('InProcess'), LostObjectStatus.inProcess);
      expect(LostObjectStatus.fromValue('Resolved'), LostObjectStatus.resolved);
      expect(LostObjectStatus.fromValue('Canceled'), LostObjectStatus.canceled);
      expect(LostObjectStatus.fromValue('cancelled'), LostObjectStatus.canceled);
      expect(LostObjectStatus.fromValue('0'), LostObjectStatus.pending);
      expect(LostObjectStatus.fromValue('2'), LostObjectStatus.resolved);
      expect(LostObjectStatus.fromValue(null), LostObjectStatus.pending);
    });

    test('LostObject se deserializa y serializa correctamente con MongoDB ID y fechas', () {
      final jsonMap = {
        'id': '671fb2c58971f49673981234',
        'title': 'Mochila negra',
        'description': 'Olvidada en biblioteca central 2do piso',
        'date': '2026-10-28T15:30:00.000Z',
        'status': 'Pending',
        'photoUrl': 'https://dominio.com/foto.jpg',
        'structureId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      };

      final obj = LostObject.fromJson(jsonMap);

      expect(obj.id, '671fb2c58971f49673981234');
      expect(obj.title, 'Mochila negra');
      expect(obj.description, 'Olvidada en biblioteca central 2do piso');
      expect(obj.status, LostObjectStatus.pending);
      expect(obj.photoUrl, 'https://dominio.com/foto.jpg');
      expect(obj.structureId, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(obj.date, isNotNull);

      final serialized = obj.toJson();
      expect(serialized['id'], '671fb2c58971f49673981234');
      expect(serialized['title'], 'Mochila negra');
      expect(serialized['status'], 'Pending');
    });

    test('PaginatedLostObjectsResponse parsea respuesta paginada completa', () {
      final jsonMap = {
        'items': [
          {
            'id': 'obj-1',
            'title': 'Notebook Asus',
            'description': 'Gris con stickers',
            'date': '2026-10-28T12:00:00Z',
            'status': 'In_Process',
            'photoUrl': 'https://dominio.com/notebook.jpg',
            'structureId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
          }
        ],
        'totalCount': 15,
        'page': 1,
        'pageSize': 10,
        'totalPages': 2,
      };

      final paginated = PaginatedLostObjectsResponse.fromJson(jsonMap);
      expect(paginated.items.length, 1);
      expect(paginated.totalCount, 15);
      expect(paginated.page, 1);
      expect(paginated.pageSize, 10);
      expect(paginated.totalPages, 2);
      expect(paginated.hasNextPage, isTrue);
      expect(paginated.hasPreviousPage, isFalse);
    });
  });

  group('CreateLostObjectDto & Validations Tests', () {
    test('Valida correctamente URLs absolutas (http/https)', () {
      expect(CreateLostObjectDto.isValidAbsoluteUrl('https://dominio.com/foto.jpg'), isTrue);
      expect(CreateLostObjectDto.isValidAbsoluteUrl('http://storage.uct.cl/lost/item.png'), isTrue);

      expect(CreateLostObjectDto.isValidAbsoluteUrl(''), isFalse);
      expect(CreateLostObjectDto.isValidAbsoluteUrl(null), isFalse);
      expect(CreateLostObjectDto.isValidAbsoluteUrl('ftp://servidor/archivo.jpg'), isFalse);
      expect(CreateLostObjectDto.isValidAbsoluteUrl('/storage/fotos/item.jpg'), isFalse);
      expect(CreateLostObjectDto.isValidAbsoluteUrl('dominio.com/foto.jpg'), isFalse);
    });

    test('Valida correctamente UUIDs estándar', () {
      expect(CreateLostObjectDto.isValidUuid('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'), isTrue);
      expect(CreateLostObjectDto.isValidUuid('A1B2C3D4-E5F6-7A8B-9C0D-1E2F3A4B5C6D'), isTrue);

      expect(CreateLostObjectDto.isValidUuid(''), isFalse);
      expect(CreateLostObjectDto.isValidUuid('12345'), isFalse);
      expect(CreateLostObjectDto.isValidUuid('a1b2c3d4-e5f6-7a8b-9c0d'), isFalse);
    });

    test('validate() lanza ArgumentError ante campos inválidos', () {
      // Título vacío
      expect(
        () => CreateLostObjectDto(
          title: '',
          description: 'Descripción válida',
          photoUrl: 'https://dominio.com/foto.jpg',
          structureId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        ).validate(),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('título'))),
      );

      // StructureId no es UUID
      expect(
        () => CreateLostObjectDto(
          title: 'Calculadora',
          description: 'Calculadora científica',
          photoUrl: 'https://dominio.com/foto.jpg',
          structureId: 'estructura-no-uuid',
        ).validate(),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('UUID'))),
      );

      // photoUrl no es URL absoluta
      expect(
        () => CreateLostObjectDto(
          title: 'Calculadora',
          description: 'Calculadora científica',
          photoUrl: '/fotos/calc.jpg',
          structureId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        ).validate(),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('photoUrl'))),
      );
    });

    test('toJson() formatea el status como número entero según la especificación', () {
      const dto = CreateLostObjectDto(
        title: 'Mochila negra',
        description: 'Olvidada en biblioteca',
        status: LostObjectStatus.pending,
        photoUrl: 'https://dominio.com/foto.jpg',
        structureId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      );

      final json = dto.toJson();
      expect(json['status'], 0);
      expect(json['title'], 'Mochila negra');
      expect(json['structureId'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(json['photoUrl'], 'https://dominio.com/foto.jpg');
    });

    test('LostObjectFilterParams genera Query Parameters correctos', () {
      const filter = LostObjectFilterParams(
        title: 'Mochila',
        structureId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        status: LostObjectStatus.inProcess,
        sortBy: 'ReportedAt',
        descending: true,
        page: 2,
        pageSize: 10,
      );

      final queryParams = filter.toQueryParams();
      expect(queryParams['title'], 'Mochila');
      expect(queryParams['structureId'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(queryParams['status'], '1');
      expect(queryParams['sortBy'], 'ReportedAt');
      expect(queryParams['descending'], 'true');
      expect(queryParams['page'], '2');
      expect(queryParams['pageSize'], '10');
    });
  });

  group('ProblemDetails RFC 7807 Parsing Tests', () {
    test('Parsea ProblemDetails completo con type, title, status, detail y extensions', () {
      const rawJson = '''
      {
        "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
        "title": "Invalid structure identifier",
        "status": 400,
        "detail": "Structure with ID a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d does not exist.",
        "instance": "/api/incident/lost-objects"
      }
      ''';

      final problem = ProblemDetails.tryParse(400, rawJson);
      expect(problem, isNotNull);
      expect(problem!.status, 400);
      expect(problem.title, 'Invalid structure identifier');
      expect(problem.detail, contains('Structure with ID'));
      expect(problem.type, contains('rfc9110'));
      expect(problem.userMessage, contains('Structure with ID'));
    });

    test('Parsea errores de validación ModelState de ASP.NET Core', () {
      const rawJson = '''
      {
        "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
        "title": "One or more validation errors occurred.",
        "status": 400,
        "errors": {
          "PhotoUrl": ["The photoUrl field is not a valid fully-qualified http, https, or ftp URL."],
          "StructureId": ["StructureId is required."]
        }
      }
      ''';

      final problem = ProblemDetails.tryParse(400, rawJson);
      expect(problem, isNotNull);
      expect(problem!.errors, isNotNull);
      expect(problem.errors!['PhotoUrl']!.first, contains('not a valid'));
      expect(problem.userMessage, contains('PhotoUrl'));
      expect(problem.userMessage, contains('StructureId'));
    });
  });

  group('LostObjectsRemoteDataSource & RepositoryImpl HTTP Integration Tests', () {
    test('createLostObject envía petición POST con headers correctos y retorna id', () async {
      String? authHeader;
      String? contentType;
      String? accept;
      String? sentBody;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/incident/lost-objects' && request.method == 'POST') {
          authHeader = request.headers['Authorization'];
          contentType = request.headers['Content-Type'];
          accept = request.headers['Accept'];
          sentBody = request.body;

          return http.Response(
            jsonEncode({'id': '671fb2c58971f49673981234'}),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final ds = LostObjectsRemoteDataSource(
        client: mockClient,
        baseUrl: 'http://localhost:5000',
        tokenProvider: () => 'sample-jwt-token-xyz',
      );

      final repo = LostObjectsRepositoryImpl(remoteDataSource: ds);

      const dto = CreateLostObjectDto(
        title: 'Mochila negra',
        description: 'Olvidada en biblioteca central 2do piso',
        status: LostObjectStatus.pending,
        photoUrl: 'https://dominio.com/foto.jpg',
        structureId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      );

      final result = await repo.createLostObject(dto);

      expect(result.id, '671fb2c58971f49673981234');
      expect(authHeader, 'Bearer sample-jwt-token-xyz');
      expect(contentType, contains('application/json'));
      expect(accept, contains('application/json'));

      final decodedBody = jsonDecode(sentBody!);
      expect(decodedBody['status'], 0);
      expect(decodedBody['photoUrl'], 'https://dominio.com/foto.jpg');
    });

    test('createLostObject arroja ProblemDetailsException ante 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
            'title': 'Validation failed',
            'status': 400,
            'detail': 'The photoUrl must be publicly accessible.',
          }),
          400,
        );
      });

      final ds = LostObjectsRemoteDataSource(
        client: mockClient,
        baseUrl: 'http://localhost:5000',
        tokenProvider: () => 'token',
      );

      const dto = CreateLostObjectDto(
        title: 'Mochila',
        description: 'Mochila olvidada',
        photoUrl: 'https://dominio.com/foto.jpg',
        structureId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      );

      expect(
        () => ds.createLostObject(dto),
        throwsA(
          isA<ProblemDetailsException>()
              .having((e) => e.errorDetail, 'errorDetail', contains('photoUrl must be publicly accessible'))
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('getLostObjects envía parámetros GET y decodifica respuesta paginada', () async {
      Map<String, String>? queryParams;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/incident/lost-objects' && request.method == 'GET') {
          queryParams = request.url.queryParameters;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': '671fb2c58971f49673981234',
                  'title': 'Mochila negra',
                  'description': 'Olvidada en biblioteca',
                  'date': '2026-10-28T15:30:00Z',
                  'status': 'Pending',
                  'photoUrl': 'https://dominio.com/foto.jpg',
                  'structureId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d'
                }
              ],
              'totalCount': 1,
              'page': 1,
              'pageSize': 10,
              'totalPages': 1
            }),
            200,
          );
        }
        return http.Response('Error', 500);
      });

      final ds = LostObjectsRemoteDataSource(
        client: mockClient,
        baseUrl: 'http://10.0.2.2:5000',
        tokenProvider: () => 'token-android',
      );

      const filter = LostObjectFilterParams(
        title: 'Mochila',
        status: LostObjectStatus.pending,
        page: 1,
        pageSize: 10,
      );

      final response = await ds.getLostObjects(filter: filter);

      expect(queryParams?['title'], 'Mochila');
      expect(queryParams?['status'], '0');
      expect(queryParams?['sortBy'], 'ReportedAt');
      expect(queryParams?['descending'], 'true');

      expect(response.items.length, 1);
      expect(response.items.first.title, 'Mochila negra');
      expect(response.items.first.status, LostObjectStatus.pending);
    });

    test('updateStatus realiza PATCH a /api/incident/lost-objects/{id}/lost/status con 204 No Content', () async {
      String? targetPath;
      String? sentBody;
      String? sentMethod;

      final mockClient = MockClient((request) async {
        targetPath = request.url.path;
        sentMethod = request.method;
        sentBody = request.body;
        return http.Response('', 204);
      });

      final ds = LostObjectsRemoteDataSource(
        client: mockClient,
        baseUrl: 'http://localhost:5000',
        tokenProvider: () => 'token',
      );

      await ds.updateStatus('671fb2c58971f49673981234', LostObjectStatus.resolved);

      expect(targetPath, '/api/incident/lost-objects/671fb2c58971f49673981234/lost/status');
      expect(sentMethod, 'PATCH');
      final decoded = jsonDecode(sentBody!);
      expect(decoded['status'], 2); // Resolved = 2
    });
  });

  group('UI Widgets Tests', () {
    testWidgets('LostObjectStatusBadge muestra etiqueta y colores correspondientes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LostObjectStatusBadge(status: LostObjectStatus.pending),
                LostObjectStatusBadge(status: LostObjectStatus.inProcess),
                LostObjectStatusBadge(status: LostObjectStatus.resolved),
                LostObjectStatusBadge(status: LostObjectStatus.canceled),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('En Proceso'), findsOneWidget);
      expect(find.text('Resuelto'), findsOneWidget);
      expect(find.text('Cancelado'), findsOneWidget);
    });

    testWidgets('CreateLostObjectScreen valida formulario y muestra feedback en tiempo real', (tester) async {
      final fakeRepo = _FakeLostObjectsRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: CreateLostObjectScreen(repository: fakeRepo),
        ),
      );

      // Botón submit
      final submitFinder = find.byType(ElevatedButton);
      expect(submitFinder, findsOneWidget);

      // Intentar enviar vacío
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      // Debe mostrar mensajes de validación
      expect(find.text('El título es obligatorio.'), findsOneWidget);
      expect(find.text('La descripción es obligatoria.'), findsOneWidget);
      expect(find.text('El ID de la estructura es obligatorio.'), findsOneWidget);
      expect(find.text('La URL de la foto es obligatoria.'), findsOneWidget);

      // Llenar campos válidos
      await tester.enterText(find.byType(TextFormField).at(0), 'Mochila Nike');
      await tester.enterText(find.byType(TextFormField).at(1), 'Olvidada en aulario B piso 2');
      await tester.enterText(find.byType(TextFormField).at(2), 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      await tester.enterText(find.byType(TextFormField).at(3), 'https://storage.uct.cl/mochila.jpg');
      await tester.pumpAndSettle();

      // Enviar formulario válido
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(fakeRepo.createdDto, isNotNull);
      expect(fakeRepo.createdDto!.title, 'Mochila Nike');
    });

    testWidgets('LostObjectsScreen renderiza listado, chips de filtro y buscador', (tester) async {
      final fakeRepo = _FakeLostObjectsRepository();
      fakeRepo.mockResponse = const PaginatedLostObjectsResponse(
        items: [
          LostObject(
            id: 'obj-123',
            title: 'Mochila Puma',
            description: 'Negra con zapatillas adentro',
            status: LostObjectStatus.pending,
            photoUrl: 'https://dominio.com/foto.jpg',
            structureId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
          ),
        ],
        totalCount: 1,
        page: 1,
        pageSize: 10,
        totalPages: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LostObjectsScreen(repository: fakeRepo),
        ),
      );

      await tester.pumpAndSettle();

      // Verifica buscador
      expect(find.byType(TextField), findsOneWidget);

      // Chips de estado
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('En Proceso'), findsOneWidget);

      // Card del objeto
      expect(find.text('Mochila Puma'), findsOneWidget);
      expect(find.text('Negra con zapatillas adentro'), findsOneWidget);
      expect(find.text('Cambiar Estado'), findsOneWidget);
    });
  });
}

class _FakeLostObjectsRepository implements LostObjectsRepository {
  CreateLostObjectDto? createdDto;
  PaginatedLostObjectsResponse? mockResponse;

  @override
  Future<CreateLostObjectResponse> createLostObject(CreateLostObjectDto dto) async {
    dto.validate();
    createdDto = dto;
    return const CreateLostObjectResponse(id: 'fake-mongo-id-999');
  }

  @override
  Future<PaginatedLostObjectsResponse> getLostObjects({LostObjectFilterParams? filter}) async {
    return mockResponse ??
        const PaginatedLostObjectsResponse(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 10,
          totalPages: 1,
        );
  }

  @override
  Future<void> updateStatus(String id, LostObjectStatus newStatus) async {}
}
