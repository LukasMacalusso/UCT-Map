import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/core/network/problem_details.dart';
import 'package:uct_map/data/datasources/reports_remote_ds.dart';
import 'package:uct_map/data/models/report_dto.dart';
import 'package:uct_map/data/repositories/reports_repository_impl.dart';
import 'package:uct_map/domain/entities/ticket.dart';
import 'package:uct_map/domain/repositories/reports_repository.dart';
import 'package:uct_map/domain/entities/lost_object.dart';
import 'package:uct_map/domain/repositories/lost_objects_repository.dart';
import 'package:uct_map/data/models/lost_object_dto.dart';
import 'package:uct_map/presentation/screens/tickets/create_ticket_screen.dart';
import 'package:uct_map/presentation/screens/tickets/tickets_screen.dart';
import 'package:uct_map/presentation/screens/tickets/widgets/ticket_status_badge.dart';

void main() {
  group('Ticket & Complaint Enums and Models Tests', () {
    test('TicketStatus enum mapea correctamente valores enteros y labels', () {
      expect(TicketStatus.pending.value, 0);
      expect(TicketStatus.inProcess.value, 1);
      expect(TicketStatus.resolved.value, 2);
      expect(TicketStatus.dismissed.value, 3);

      expect(TicketStatus.pending.label, 'Pendiente');
      expect(TicketStatus.inProcess.label, 'En Proceso');
      expect(TicketStatus.resolved.label, 'Resuelto');
      expect(TicketStatus.dismissed.label, 'Desestimado');

      // Parsing de enteros
      expect(TicketStatus.fromValue(0), TicketStatus.pending);
      expect(TicketStatus.fromValue(1), TicketStatus.inProcess);
      expect(TicketStatus.fromValue(2), TicketStatus.resolved);
      expect(TicketStatus.fromValue(3), TicketStatus.dismissed);

      // Parsing de strings
      expect(TicketStatus.fromValue('Pending'), TicketStatus.pending);
      expect(TicketStatus.fromValue('In_Process'), TicketStatus.inProcess);
      expect(TicketStatus.fromValue('Resolved'), TicketStatus.resolved);
      expect(TicketStatus.fromValue('Dismissed'), TicketStatus.dismissed);
      expect(TicketStatus.fromValue('desestimado'), TicketStatus.dismissed);
      expect(TicketStatus.fromValue(null), TicketStatus.pending);
    });

    test('ComplaintStatus enum mapea correctamente valores 0..3 y labels', () {
      expect(ComplaintStatus.claim.value, 0);
      expect(ComplaintStatus.found.value, 1);
      expect(ComplaintStatus.match.value, 2);
      expect(ComplaintStatus.pickup.value, 3);

      expect(ComplaintStatus.claim.label, 'Reclamo');
      expect(ComplaintStatus.found.label, 'Hallazgo');
      expect(ComplaintStatus.match.label, 'Coincidencia');
      expect(ComplaintStatus.pickup.label, 'Retiro');

      expect(ComplaintStatus.fromValue(0), ComplaintStatus.claim);
      expect(ComplaintStatus.fromValue(1), ComplaintStatus.found);
      expect(ComplaintStatus.fromValue(2), ComplaintStatus.match);
      expect(ComplaintStatus.pickup, ComplaintStatus.fromValue('Pickup'));
      expect(ComplaintStatus.fromValue('Reclamo'), ComplaintStatus.claim);
      expect(ComplaintStatus.fromValue(null), ComplaintStatus.claim);
    });

    test('Ticket y ComplaintDetails serializan y deserializan formato exacto del backend', () {
      final jsonMap = {
        'id': '671fb3e98971f49673981299',
        'userRefId': '27da61e1-cb64-46e6-96f0-394a44d08577',
        'structureRefId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        'ticketType': 0,
        'isActive': true,
        'reportedAt': '2026-10-28T15:30:00Z',
        'complaintDetails': {
          'title': 'Reclamo de pertenencia',
          'description': 'Dejé la mochila en la sala 201',
          'status': 0,
        },
        'lostObjectId': '671fb2c58971f49673981234',
      };

      final ticket = Ticket.fromJson(jsonMap);

      expect(ticket.id, '671fb3e98971f49673981299');
      expect(ticket.userRefId, '27da61e1-cb64-46e6-96f0-394a44d08577');
      expect(ticket.structureRefId, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(ticket.ticketType, TicketStatus.pending);
      expect(ticket.isActive, isTrue);
      expect(ticket.lostObjectId, '671fb2c58971f49673981234');

      expect(ticket.complaintDetails, isNotNull);
      expect(ticket.complaintDetails!.title, 'Reclamo de pertenencia');
      expect(ticket.complaintDetails!.status, ComplaintStatus.claim);

      final serialized = ticket.toJson();
      expect(serialized['ticketType'], 0);
      expect(serialized['structureRefId'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(serialized['complaintDetails']['title'], 'Reclamo de pertenencia');
    });

    test('PaginatedReportsResponse parsea respuesta paginada completa', () {
      final jsonMap = {
        'items': [
          {
            'id': 'tk-1',
            'structureRefId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
            'ticketType': 1,
            'isActive': true,
            'reportedAt': '2026-10-28T15:30:00Z',
          }
        ],
        'totalCount': 5,
        'page': 1,
        'pageSize': 10,
        'totalPages': 1,
      };

      final res = PaginatedReportsResponse.fromJson(jsonMap);
      expect(res.items.length, 1);
      expect(res.totalCount, 5);
      expect(res.items.first.ticketType, TicketStatus.inProcess);
    });
  });

  group('CreateReportDto & Validations Tests', () {
    test('Valida structureRefId como UUID obligatorio', () {
      expect(
        () => const CreateReportDto(
          structureRefId: '',
        ).validate(),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('obligatorio'))),
      );

      expect(
        () => const CreateReportDto(
          structureRefId: 'no-uuid-string',
        ).validate(),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('UUID'))),
      );
    });

    test('Valida campos de queja si se incluye complaint', () {
      expect(
        () => const CreateReportDto(
          structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
          complaint: CreateComplaintDto(title: '', description: 'Desc'),
        ).validate(),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('título'))),
      );

      expect(
        () => const CreateReportDto(
          structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
          complaint: CreateComplaintDto(title: 'Título válido', description: 'Cort'),
        ).validate(),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message', contains('descripción'))),
      );
    });

    test('toJson() serializa ticketType y complaint.status como números enteros', () {
      const dto = CreateReportDto(
        structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        ticketType: TicketStatus.pending,
        isActive: true,
        lostObjectId: '671fb2c58971f49673981234',
        complaint: CreateComplaintDto(
          title: 'Reclamo de pertenencia',
          description: 'Dejé la mochila en la sala 201',
          status: ComplaintStatus.claim,
        ),
      );

      final json = dto.toJson();
      expect(json['structureRefId'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(json['ticketType'], 0);
      expect(json['isActive'], isTrue);
      expect(json['lostObjectId'], '671fb2c58971f49673981234');
      expect(json['complaint']['status'], 0);
      expect(json['complaint']['title'], 'Reclamo de pertenencia');
    });

    test('ReportFilterParams genera query params con formato anidado de ASP.NET Core', () {
      const filter = ReportFilterParams(
        userRefId: '27da61e1-cb64-46e6-96f0-394a44d08577',
        structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        type: TicketStatus.inProcess,
        isActive: true,
        complaintTitle: 'Mochila',
        complaintStatus: ComplaintStatus.claim,
        sortBy: 'ReportedAt',
        descending: true,
        page: 1,
        pageSize: 10,
      );

      final queryParams = filter.toQueryParams();
      expect(queryParams['userRefId'], '27da61e1-cb64-46e6-96f0-394a44d08577');
      expect(queryParams['structureRefId'], 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(queryParams['type'], '1');
      expect(queryParams['isActive'], 'true');
      expect(queryParams['complaintDetails.title'], 'Mochila');
      expect(queryParams['complaintDetails.status'], '0');
      expect(queryParams['sortBy'], 'ReportedAt');
      expect(queryParams['descending'], 'true');
    });
  });

  group('ReportsRemoteDataSource & RepositoryImpl HTTP Integration Tests', () {
    test('createReport envía POST con headers y retorna MongoDB id', () async {
      String? authHeader;
      String? contentType;
      String? sentBody;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/incident/reports' && request.method == 'POST') {
          authHeader = request.headers['Authorization'];
          contentType = request.headers['Content-Type'];
          sentBody = request.body;

          return http.Response(
            jsonEncode({'id': '671fb3e98971f49673981299'}),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final ds = ReportsRemoteDataSource(
        client: mockClient,
        baseUrl: 'http://localhost:5000',
        tokenProvider: () => 'jwt-reports-token',
      );
      final repo = ReportsRepositoryImpl(remoteDataSource: ds);

      const dto = CreateReportDto(
        structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
        ticketType: TicketStatus.pending,
        complaint: CreateComplaintDto(
          title: 'Gotera',
          description: 'Gotera en techo sala 102',
          status: ComplaintStatus.claim,
        ),
      );

      final result = await repo.createReport(dto);

      expect(result.id, '671fb3e98971f49673981299');
      expect(authHeader, 'Bearer jwt-reports-token');
      expect(contentType, contains('application/json'));

      final decoded = jsonDecode(sentBody!);
      expect(decoded['ticketType'], 0);
      expect(decoded['complaint']['title'], 'Gotera');
    });

    test('createReport lanza ProblemDetailsException ante 400 Bad Request', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
            'title': 'Structure not found',
            'status': 400,
            'detail': 'Structure UUID is not registered in Campus Service.',
          }),
          400,
        );
      });

      final ds = ReportsRemoteDataSource(
        client: mockClient,
        baseUrl: 'http://localhost:5000',
        tokenProvider: () => 'token',
      );

      const dto = CreateReportDto(
        structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      );

      expect(
        () => ds.createReport(dto),
        throwsA(
          isA<ProblemDetailsException>()
              .having((e) => e.errorDetail, 'errorDetail', contains('Structure UUID is not registered'))
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('getReports envía query params y decodifica respuesta paginada 200 OK', () async {
      Map<String, String>? capturedParams;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/incident/reports' && request.method == 'GET') {
          capturedParams = request.url.queryParameters;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'id': '671fb3e98971f49673981299',
                  'structureRefId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
                  'ticketType': 0,
                  'isActive': true,
                  'reportedAt': '2026-10-28T15:30:00Z',
                  'complaintDetails': {
                    'title': 'Reclamo',
                    'description': 'Mochila olvidada',
                    'status': 0
                  }
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

      final ds = ReportsRemoteDataSource(
        client: mockClient,
        baseUrl: 'http://10.0.2.2:5000',
        tokenProvider: () => 'token-android',
      );

      const filter = ReportFilterParams(
        complaintTitle: 'Reclamo',
        type: TicketStatus.pending,
      );

      final response = await ds.getReports(filter: filter);

      expect(capturedParams?['complaintDetails.title'], 'Reclamo');
      expect(capturedParams?['type'], '0');
      expect(response.items.length, 1);
      expect(response.items.first.complaintDetails?.title, 'Reclamo');
    });

    test('getReportById consulta GET /api/incident/reports/{id} y retorna Ticket', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/incident/reports/tk-123') {
          return http.Response(
            jsonEncode({
              'id': 'tk-123',
              'structureRefId': 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
              'ticketType': 2,
              'isActive': true,
              'reportedAt': '2026-10-28T15:30:00Z',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final ds = ReportsRemoteDataSource(client: mockClient, baseUrl: 'http://localhost:5000');
      final ticket = await ds.getReportById('tk-123');

      expect(ticket.id, 'tk-123');
      expect(ticket.ticketType, TicketStatus.resolved);
    });

    test('updateReportStatus realiza PATCH a /api/incident/reports/{id}/report/status con 204 No Content', () async {
      String? sentPath;
      String? sentBody;
      String? sentMethod;

      final mockClient = MockClient((request) async {
        sentPath = request.url.path;
        sentMethod = request.method;
        sentBody = request.body;
        return http.Response('', 204);
      });

      final ds = ReportsRemoteDataSource(client: mockClient, baseUrl: 'http://localhost:5000');

      await ds.updateReportStatus(
        '671fb3e98971f49673981299',
        status: TicketStatus.inProcess,
        complainStatus: ComplaintStatus.match,
      );

      expect(sentPath, '/api/incident/reports/671fb3e98971f49673981299/report/status');
      expect(sentMethod, 'PATCH');
      final decoded = jsonDecode(sentBody!);
      expect(decoded['status'], 1); // inProcess = 1
      expect(decoded['complainStatus'], 2); // match = 2
    });
  });

  group('UI Widgets Tests for Tickets', () {
    testWidgets('TicketStatusBadge y ComplaintStatusBadge muestran labels y estilos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TicketStatusBadge(status: TicketStatus.pending),
                TicketStatusBadge(status: TicketStatus.inProcess),
                TicketStatusBadge(status: TicketStatus.resolved),
                TicketStatusBadge(status: TicketStatus.dismissed),
                ComplaintStatusBadge(status: ComplaintStatus.claim),
                ComplaintStatusBadge(status: ComplaintStatus.found),
                ComplaintStatusBadge(status: ComplaintStatus.match),
                ComplaintStatusBadge(status: ComplaintStatus.pickup),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('En Proceso'), findsOneWidget);
      expect(find.text('Resuelto'), findsOneWidget);
      expect(find.text('Desestimado'), findsOneWidget);

      expect(find.text('Reclamo'), findsOneWidget);
      expect(find.text('Hallazgo'), findsOneWidget);
      expect(find.text('Coincidencia'), findsOneWidget);
      expect(find.text('Retiro'), findsOneWidget);
    });

    testWidgets('CreateTicketScreen valida formulario y envía datos', (tester) async {
      final fakeRepo = _FakeReportsRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: CreateTicketScreen(repository: fakeRepo),
        ),
      );

      final submitBtn = find.byType(ElevatedButton);
      expect(submitBtn, findsOneWidget);

      // Intentar enviar vacío
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('El ID de la estructura es obligatorio.'), findsOneWidget);
      expect(find.text('El título de la queja es obligatorio.'), findsOneWidget);
      expect(find.text('La descripción es obligatoria.'), findsOneWidget);

      // Ingresar campos válidos
      await tester.enterText(find.byType(TextFormField).at(0), 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      await tester.enterText(find.byType(TextFormField).at(1), 'Reclamo de notebook');
      await tester.enterText(find.byType(TextFormField).at(2), 'Olvidado en sala de computación');
      await tester.pumpAndSettle();

      // Enviar
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(fakeRepo.createdDto, isNotNull);
      expect(fakeRepo.createdDto!.structureRefId, 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d');
      expect(fakeRepo.createdDto!.complaint?.title, 'Reclamo de notebook');
    });

    testWidgets('CreateTicketScreen abre modal selector de objetos perdidos y selecciona uno', (tester) async {
      final fakeReportsRepo = _FakeReportsRepository();
      final fakeLostRepo = _FakeLostObjectsRepoForPicker();

      await tester.pumpWidget(
        MaterialApp(
          home: CreateTicketScreen(
            repository: fakeReportsRepo,
            lostObjectsRepository: fakeLostRepo,
          ),
        ),
      );

      // Tocar el botón selector de objetos perdidos
      expect(find.text('Seleccionar objeto perdido...'), findsOneWidget);
      await tester.tap(find.text('Seleccionar objeto perdido...'));
      await tester.pumpAndSettle();

      // Debe abrirse el modal inferior
      expect(find.text('Seleccionar Objeto Perdido'), findsOneWidget);
      expect(find.text('Mochila Puma'), findsOneWidget);

      // Tocar el objeto en la lista
      await tester.tap(find.text('Mochila Puma'));
      await tester.pumpAndSettle();

      // El modal debe haberse cerrado y ahora debe mostrar la tarjeta del objeto seleccionado
      expect(find.text('ID: 671fb2c58971f49673981234'), findsOneWidget);
      expect(find.text('Cambiar por otro objeto'), findsOneWidget);
    });

    testWidgets('TicketsScreen renderiza listado y filtros', (tester) async {
      final fakeRepo = _FakeReportsRepository();
      fakeRepo.mockResponse = const PaginatedReportsResponse(
        items: [
          Ticket(
            id: 'rep-99',
            structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
            ticketType: TicketStatus.pending,
            isActive: true,
            reportedAt: DateTime(2026, 10, 28),
            complaintDetails: ComplaintDetails(
              title: 'Reclamo por cargador',
              description: 'Cargador blanco de celular',
              status: ComplaintStatus.claim,
            ),
          ),
        ],
        totalCount: 1,
        page: 1,
        pageSize: 10,
        totalPages: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TicketsScreen(repository: fakeRepo),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Reclamo por cargador'), findsOneWidget);
      expect(find.text('Cargador blanco de celular'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Cambiar Estado'), findsOneWidget);
    });
  });
}

class _FakeLostObjectsRepoForPicker implements LostObjectsRepository {
  @override
  Future<CreateLostObjectResponse> createLostObject(CreateLostObjectDto dto) async {
    return const CreateLostObjectResponse(id: 'fake');
  }

  @override
  Future<PaginatedLostObjectsResponse> getLostObjects({LostObjectFilterParams? filter}) async {
    return const PaginatedLostObjectsResponse(
      items: [
        LostObject(
          id: '671fb2c58971f49673981234',
          title: 'Mochila Puma',
          description: 'Negra con franja roja',
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
  }

  @override
  Future<void> updateStatus(String id, LostObjectStatus newStatus) async {}
}

class _FakeReportsRepository implements ReportsRepository {
  CreateReportDto? createdDto;
  PaginatedReportsResponse? mockResponse;

  @override
  Future<CreateReportResponse> createReport(CreateReportDto dto) async {
    dto.validate();
    createdDto = dto;
    return const CreateReportResponse(id: 'fake-mongo-rep-99');
  }

  @override
  Future<PaginatedReportsResponse> getReports({ReportFilterParams? filter}) async {
    return mockResponse ??
        const PaginatedReportsResponse(
          items: [],
          totalCount: 0,
          page: 1,
          pageSize: 10,
          totalPages: 1,
        );
  }

  @override
  Future<Ticket> getReportById(String id) async {
    return const Ticket(
      id: 'fake-id',
      structureRefId: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d',
      ticketType: TicketStatus.pending,
      isActive: true,
      reportedAt: DateTime(2026, 10, 28),
    );
  }

  @override
  Future<void> updateReportStatus(
    String id, {
    required TicketStatus status,
    ComplaintStatus? complainStatus,
  }) async {}
}
