import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/problem_details.dart';
import 'package:uct_map/data/datasources/campus_remote_ds.dart';
import 'package:uct_map/data/models/lost_object_dto.dart';
import 'package:uct_map/data/models/report_dto.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/entities/lost_object.dart';
import 'package:uct_map/domain/entities/ticket.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/domain/repositories/lost_objects_repository.dart';
import 'package:uct_map/domain/repositories/reports_repository.dart';
import 'package:uct_map/presentation/screens/tickets/create_ticket_screen.dart';
import 'package:uct_map/presentation/screens/tickets/ticket_detail_screen.dart';
import 'package:uct_map/presentation/screens/tickets/tickets_screen.dart';

const _structureA = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';
const _structureB = 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e';
const _structureOtherCampus = 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f';

class _MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> clear() async => _token = null;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;
}

Future<SessionController> _signInWithRole(String role) async {
  final session = SessionController(storage: _MemoryTokenStorage());
  await session.ready;
  final payload = {
    'sub': 'user-123',
    'email': 'tester@uct.cl',
    'role': role,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
    'iss': 'https://identity-api',
    'aud': 'api-gateway',
  };
  String enc(Object json) => base64Url.encode(utf8.encode(jsonEncode(json)));
  await session.signInReal(
    AuthLoginResult(
      userId: 'user-123',
      email: 'tester@uct.cl',
      token: '${enc({'alg': 'HS256'})}.${enc(payload)}.sig',
    ),
  );
  ApiClientProvider.reset(session: session);
  return session;
}

CampusRemoteDataSource _campusFixture() => CampusRemoteDataSource(
  client: MockClient((request) async {
    final path = request.url.path;
    final campusId = request.url.queryParameters['campusId'];

    if (path.endsWith('/campuses')) {
      return http.Response(
        jsonEncode([
          {
            'id': 'campus-jp2',
            'name': 'Campus San Juan Pablo II',
            'address': 'Rudecindo Ortega 02950',
            'latitude': -38.702,
            'longitude': -72.548,
          },
          {
            'id': 'campus-sf',
            'name': 'Campus San Francisco',
            'address': 'Manuel Montt 56',
            'latitude': -38.736,
            'longitude': -72.590,
          },
        ]),
        200,
      );
    }

    if (path.endsWith('/campuses/campus-jp2')) {
      return http.Response(
        jsonEncode({
          'id': 'campus-jp2',
          'name': 'Campus San Juan Pablo II',
          'address': 'Rudecindo Ortega 02950',
          'latitude': -38.702,
          'longitude': -72.548,
        }),
        200,
      );
    }

    if (path.endsWith('/buildings/locations')) {
      final all = [
        {
          'id': _structureB,
          'name': 'Edificio C',
          'location': {'latitude': -38.702, 'longitude': -72.548},
          'metadata': {
            'campusId': 'campus-jp2',
            'floorsCount': 3,
            'schedule': '08:00-20:00',
            'services': <String>[],
          },
        },
      ];
      return http.Response(jsonEncode(all), 200);
    }

    if (path.endsWith('/buildings')) {
      final all = [
        {
          'id': _structureB,
          'name': 'Edificio C',
          'campusId': 'campus-jp2',
          'floorsCount': 3,
          'latitude': -38.702,
          'longitude': -72.548,
        },
      ];
      final filtered = campusId == null
          ? all
          : all.where((e) => e['campusId'] == campusId).toList();
      return http.Response(jsonEncode(filtered), 200);
    }

    if (path.endsWith('/structures/locations')) {
      final all = [
        {
          'id': _structureA,
          'name': 'Biblioteca',
          'location': {'latitude': -38.702, 'longitude': -72.548},
          'metadata': {
            'campusId': 'campus-jp2',
            'categoryId': 'cat-1',
            'categoryName': 'Académico',
          },
        },
        {
          'id': _structureOtherCampus,
          'name': 'Casino San Francisco',
          'location': {'latitude': -38.736, 'longitude': -72.590},
          'metadata': {
            'campusId': 'campus-sf',
            'categoryId': 'cat-2',
            'categoryName': 'Servicios',
          },
        },
      ];
      return http.Response(jsonEncode(all), 200);
    }

    if (path.endsWith('/structures')) {
      final all = [
        {
          'id': _structureA,
          'name': 'Biblioteca',
          'campusId': 'campus-jp2',
          'categoryId': 'cat-1',
          'latitude': -38.702,
          'longitude': -72.548,
        },
        {
          'id': _structureOtherCampus,
          'name': 'Casino San Francisco',
          'campusId': 'campus-sf',
          'categoryId': 'cat-2',
          'latitude': -38.736,
          'longitude': -72.590,
        },
      ];
      final filtered = campusId == null
          ? all
          : all.where((e) => e['campusId'] == campusId).toList();
      return http.Response(jsonEncode(filtered), 200);
    }

    if (path.endsWith('/structures/$_structureA')) {
      return http.Response(
        jsonEncode({
          'id': _structureA,
          'name': 'Biblioteca',
          'campusId': 'campus-jp2',
          'categoryId': 'cat-1',
          'latitude': -38.702,
          'longitude': -72.548,
        }),
        200,
      );
    }

    return http.Response('Not Found', 404);
  }),
);

class _FakeLostObjectsRepo implements LostObjectsRepository {
  @override
  Future<PaginatedLostObjectsResponse> getLostObjects({
    LostObjectFilterParams? filter,
  }) async => const PaginatedLostObjectsResponse(
    items: [
      LostObject(
        id: '671fb2c58971f49673981234',
        title: 'Mochila Azul',
        description: 'Encontrada en Biblioteca',
        status: LostObjectStatus.pending,
        photoUrl: '',
        structureId: _structureA,
      ),
    ],
    totalCount: 1,
    page: 1,
    pageSize: 10,
    totalPages: 1,
  );

  @override
  Future<CreateLostObjectResponse> createLostObject(CreateLostObjectDto dto) =>
      throw UnimplementedError();

  @override
  Future<void> deleteLostObject(String id) => throw UnimplementedError();

  @override
  Future<LostObject> getLostObjectById(String id) => throw UnimplementedError();

  @override
  Future<void> updateStatus(String id, LostObjectStatus newStatus) =>
      throw UnimplementedError();
}

class _StatefulReportsRepo implements ReportsRepository {
  _StatefulReportsRepo(List<Ticket> initial) : items = List.of(initial);

  final List<Ticket> items;
  final List<ReportFilterParams?> receivedFilters = [];
  final List<({String id, TicketStatus status, ComplaintStatus? complain})>
  statusUpdates = [];
  final List<String> callOrder = [];

  CreateReportDto? lastCreated;
  Completer<void>? pendingPatch;
  Object? patchError;

  @override
  Future<CreateReportResponse> createReport(CreateReportDto dto) async {
    dto.validate();
    lastCreated = dto;
    return const CreateReportResponse(id: '671fb3e98971f49673981299');
  }

  @override
  Future<void> deleteReport(String id) async {
    items.removeWhere((t) => t.id == id);
  }

  @override
  Future<Ticket> getReportById(String id) async {
    callOrder.add('getReportById');
    return items.firstWhere((t) => t.id == id);
  }

  @override
  Future<PaginatedReportsResponse> getReports({
    ReportFilterParams? filter,
  }) async {
    receivedFilters.add(filter);
    final f = filter ?? const ReportFilterParams();
    var filtered = items.where((t) {
      if (f.structureRefId != null && t.structureRefId != f.structureRefId) {
        return false;
      }
      if (f.type != null && t.ticketType != f.type) {
        return false;
      }
      if (f.complaintTitle != null && f.complaintTitle!.isNotEmpty) {
        final q = f.complaintTitle!.toLowerCase();
        final title = t.complaintDetails?.title.toLowerCase() ?? '';
        if (!title.contains(q)) return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final cmp = f.sortBy == 'Status'
          ? a.ticketType.value.compareTo(b.ticketType.value)
          : a.reportedAt.compareTo(b.reportedAt);
      return f.descending ? -cmp : cmp;
    });

    final totalCount = filtered.length;
    final totalPages = totalCount == 0 ? 0 : (totalCount / f.pageSize).ceil();
    final pageItems = filtered
        .skip((f.page - 1) * f.pageSize)
        .take(f.pageSize)
        .toList();

    return PaginatedReportsResponse(
      items: pageItems,
      totalCount: totalCount,
      page: f.page,
      pageSize: f.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<void> updateReportStatus(
    String id, {
    required TicketStatus status,
    ComplaintStatus? complainStatus,
  }) async {
    callOrder.add('updateReportStatus:start');
    if (pendingPatch != null) {
      await pendingPatch!.future;
    }
    if (patchError != null) {
      throw patchError!;
    }
    statusUpdates.add((id: id, status: status, complain: complainStatus));
    final idx = items.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final current = items[idx];
      items[idx] = current.copyWith(
        ticketType: status,
        complaintDetails: current.complaintDetails?.copyWith(
          status: complainStatus ?? current.complaintDetails!.status,
        ),
      );
    }
    callOrder.add('updateReportStatus:end');
  }
}

Ticket _ticket(
  int index, {
  String structureRefId = _structureA,
  TicketStatus status = TicketStatus.pending,
  ComplaintStatus complaintStatus = ComplaintStatus.claim,
  String? title,
}) => Ticket(
  id: 'tk-$index',
  structureRefId: structureRefId,
  ticketType: status,
  isActive: true,
  reportedAt: DateTime(2026, 11, 1).add(Duration(hours: index)),
  complaintDetails: ComplaintDetails(
    title: title ?? 'Incidencia $index',
    description: 'Descripción de prueba $index',
    status: complaintStatus,
  ),
);

void main() {
  tearDown(() {
    ApiClientProvider.reset();
  });

  group('1. Creación de reportes', () {
    test('CreateReportDto valida formato de lostObjectId (24 hex chars)', () {
      expect(
        () => const CreateReportDto(
          structureRefId: _structureA,
          lostObjectId: 'id-invalido',
        ).validate(),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('ObjectId'),
          ),
        ),
      );

      expect(
        () => const CreateReportDto(
          structureRefId: _structureA,
          lostObjectId: '671fb2c58971f49673981234',
        ).validate(),
        returnsNormally,
      );
    });

    testWidgets(
      'CreateTicketScreen valida ObjectId manual inválido antes de enviar',
      (tester) async {
        final repo = _StatefulReportsRepo([]);
        await tester.pumpWidget(
          MaterialApp(
            home: CreateTicketScreen(
              repository: repo,
              campusRepository: _campusFixture(),
              initialCampusId: 'campus-jp2',
              initialLocationId: _structureA,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('¿Prefieres ingresar el ID manual?'));
        await tester.pumpAndSettle();

        final manualField = find.widgetWithText(
          TextFormField,
          'Ej. 671fb2c58971f49673981234 (MongoDB ObjectId)',
        );
        await tester.enterText(manualField, 'no-es-object-id');

        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Ej. Reclamo de pertenencia olvidada',
          ),
          'Ventana rota',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Detalla lo ocurrido, lugar, fecha y motivo...',
          ),
          'Ventana dañada en el primer piso',
        );

        final submit = find.byType(ElevatedButton);
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Debe ser un ObjectId válido de 24 caracteres hexadecimales.',
          ),
          findsOneWidget,
        );
        expect(repo.lastCreated, isNull);
      },
    );

    testWidgets(
      'Seleccionar objeto perdido autocompleta campus y ubicación en CampusLocationPicker',
      (tester) async {
        final repo = _StatefulReportsRepo([]);
        await tester.pumpWidget(
          MaterialApp(
            home: CreateTicketScreen(
              repository: repo,
              campusRepository: _campusFixture(),
              lostObjectsRepository: _FakeLostObjectsRepo(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Seleccionar objeto perdido...'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mochila Azul'));
        await tester.pumpAndSettle();

        // El picker debe haber resuelto automáticamente Campus San Juan Pablo II y Biblioteca
        expect(find.text('Campus San Juan Pablo II'), findsOneWidget);
        expect(find.text('Biblioteca'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Ej. Reclamo de pertenencia olvidada',
          ),
          'Reclamo mochila azul',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Detalla lo ocurrido, lugar, fecha y motivo...',
          ),
          'Es mi mochila olvidada ayer',
        );

        final submit = find.byType(ElevatedButton);
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();

        expect(repo.lastCreated, isNotNull);
        expect(repo.lastCreated!.structureRefId, _structureA);
        expect(repo.lastCreated!.lostObjectId, '671fb2c58971f49673981234');
      },
    );
  });

  group('2. Ubicación en reportes', () {
    testWidgets(
      'TicketsScreen muestra ubicación resuelta, filtra por campus y Limpiar Filtros limpia campus',
      (tester) async {
        final repo = _StatefulReportsRepo([
          _ticket(1, structureRefId: _structureA, title: 'Falla Biblioteca'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: TicketsScreen(
              repository: repo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Biblioteca · Campus San Juan Pablo II'),
          findsOneWidget,
        );

        // Filtrar por Campus San Francisco (donde no hay reportes)
        await tester.tap(find.byTooltip('Filtrar ubicación'));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Campus San Francisco').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();

        expect(find.text('No se encontraron reportes'), findsOneWidget);
        expect(find.text('Campus San Francisco'), findsOneWidget);

        // Limpiar Filtros debe restablecer también el filtro de campus
        await tester.tap(find.text('Limpiar Filtros'));
        await tester.pumpAndSettle();

        expect(find.text('Todos los campus'), findsOneWidget);
        expect(find.text('Falla Biblioteca'), findsOneWidget);
      },
    );

    testWidgets(
      'TicketDetailScreen resuelve y muestra la ubicación del reporte',
      (tester) async {
        final session = await _signInWithRole('Student');
        try {
          final repo = _StatefulReportsRepo([
            _ticket(1, structureRefId: _structureA, title: 'Gotera Biblioteca'),
          ]);

          await tester.pumpWidget(
            MaterialApp(
              home: TicketDetailScreen(
                ticketId: 'tk-1',
                repository: repo,
                campusRepository: _campusFixture(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.text('Biblioteca · Campus San Juan Pablo II'),
            findsOneWidget,
          );
          expect(find.text('Ver ubicación'), findsOneWidget);
        } finally {
          await session.signOut();
        }
      },
    );
  });

  group('3. Filtros y ordenamiento', () {
    testWidgets(
      'TicketsScreen filtra por estado, búsqueda por título y ordenamiento',
      (tester) async {
        final repo = _StatefulReportsRepo([
          _ticket(1, status: TicketStatus.pending, title: 'Silla rota'),
          _ticket(2, status: TicketStatus.resolved, title: 'Proyector OK'),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: TicketsScreen(
              repository: repo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Silla rota'), findsOneWidget);
        expect(find.text('Proyector OK'), findsOneWidget);

        // Filtrar por estado Resueltos
        await tester.tap(find.text('Resueltos'));
        await tester.pumpAndSettle();

        expect(find.text('Silla rota'), findsNothing);
        expect(find.text('Proyector OK'), findsOneWidget);
        expect(repo.receivedFilters.last?.type, TicketStatus.resolved);

        // Volver a Todos y buscar por texto
        await tester.tap(find.text('Todos'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Silla');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();

        expect(find.text('Silla rota'), findsOneWidget);
        expect(find.text('Proyector OK'), findsNothing);
        expect(repo.receivedFilters.last?.complaintTitle, 'Silla');

        // Cambiar ordenamiento desde la hoja de opciones
        await tester.tap(find.byTooltip('Ordenar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Estado (Status)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();

        expect(repo.receivedFilters.last?.sortBy, 'Status');
        expect(repo.receivedFilters.last?.page, 1);
      },
    );
  });

  group('4. Paginación', () {
    test(
      'PaginatedReportsResponse calcula totalPages si el servidor lo omite',
      () {
        final res = PaginatedReportsResponse.fromJson({
          'items': const [],
          'totalCount': 23,
          'page': 1,
          'pageSize': 10,
        });
        expect(res.totalPages, 3);
        expect(res.hasNextPage, isTrue);
        expect(res.hasPreviousPage, isFalse);
      },
    );

    testWidgets(
      'TicketsScreen navega entre páginas y reajusta página si queda vacía',
      (tester) async {
        final repo = _StatefulReportsRepo([
          for (var i = 1; i <= 11; i++) _ticket(i),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: TicketsScreen(
              repository: repo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Desplazarse a la barra de paginación
        await tester.scrollUntilVisible(
          find.text('Siguiente'),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        expect(find.text('Página 1 de 2\n(11 reportes)'), findsOneWidget);

        // Ir a página 2
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();

        expect(find.text('Página 2 de 2\n(11 reportes)'), findsOneWidget);
        expect(find.text('Incidencia 1'), findsOneWidget);

        // Eliminar el último elemento para que la página 2 quede vacía y refrescar
        repo.items.removeWhere((t) => t.id == 'tk-1');
        await tester.tap(find.byTooltip('Actualizar'));
        await tester.pumpAndSettle();

        // Debe volver automáticamente a la página 1 en lugar de mostrar vacío
        expect(find.text('No se encontraron reportes'), findsNothing);
        expect(find.text('Incidencia 11'), findsOneWidget);
      },
    );
  });

  group('5. Cambios de estado', () {
    testWidgets(
      'TicketsScreen deshabilita Aplicar Cambios si no hay cambios y envía PATCH al modificar estado',
      (tester) async {
        final session = await _signInWithRole('ComplaintsOfficer');
        try {
          final repo = _StatefulReportsRepo([
            _ticket(
              1,
              status: TicketStatus.pending,
              complaintStatus: ComplaintStatus.claim,
              title: 'Puerta trabada',
            ),
          ]);

          await tester.pumpWidget(
            MaterialApp(
              home: TicketsScreen(
                repository: repo,
                campusRepository: _campusFixture(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Cambiar Estado'));
          await tester.pumpAndSettle();

          // Sin cambios, el botón debe estar deshabilitado
          final applyBtn = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Aplicar Cambios'),
          );
          expect(applyBtn.onPressed, isNull);

          // Seleccionar En Proceso y Hallazgo
          await tester.tap(find.widgetWithText(ChoiceChip, 'En Proceso'));
          await tester.tap(find.widgetWithText(ChoiceChip, 'Hallazgo'));
          await tester.pumpAndSettle();

          await tester.ensureVisible(find.text('Aplicar Cambios'));
          await tester.tap(find.text('Aplicar Cambios'));
          await tester.pumpAndSettle();

          expect(repo.statusUpdates.length, 1);
          expect(repo.statusUpdates.first.status, TicketStatus.inProcess);
          expect(repo.statusUpdates.first.complain, ComplaintStatus.found);
        } finally {
          await session.signOut();
        }
      },
    );

    testWidgets(
      'TicketDetailScreen espera a que termine el PATCH antes de recargar el detalle y reporta error real',
      (tester) async {
        final session = await _signInWithRole('ComplaintsOfficer');
        try {
          final repo = _StatefulReportsRepo([
            _ticket(1, status: TicketStatus.pending, title: 'Luz quemada'),
          ]);
          repo.pendingPatch = Completer<void>();

          await tester.pumpWidget(
            MaterialApp(
              home: TicketDetailScreen(
                ticketId: 'tk-1',
                repository: repo,
                campusRepository: _campusFixture(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          repo.callOrder.clear();

          await tester.tap(find.text('Cambiar Estado del Reporte'));
          await tester.pumpAndSettle();

          // Sin cambios debe estar deshabilitado
          final saveBtn = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Guardar Cambios'),
          );
          expect(saveBtn.onPressed, isNull);

          // Cambiar a Resuelto
          await tester.tap(find.widgetWithText(ChoiceChip, 'Resuelto'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Guardar Cambios'));
          await tester.tap(find.text('Guardar Cambios'));
          await tester.pump();

          // Mientras el PATCH no termina, NO debe haber llamado getReportById
          expect(repo.callOrder, ['updateReportStatus:start']);

          repo.pendingPatch!.complete();
          await tester.pumpAndSettle();

          expect(repo.callOrder, [
            'updateReportStatus:start',
            'updateReportStatus:end',
            'getReportById',
          ]);
          expect(find.text('Resuelto'), findsOneWidget);

          // Verificar que errores ProblemDetails se muestran al usuario
          repo.pendingPatch = null;
          repo.patchError = ProblemDetailsException(
            const ProblemDetails(
              status: 403,
              title: 'Forbidden',
              detail: 'Sin permisos para modificar este reporte.',
            ),
          );

          await tester.tap(find.text('Cambiar Estado del Reporte'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, 'Desestimado'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Guardar Cambios'));
          await tester.tap(find.text('Guardar Cambios'));
          await tester.pumpAndSettle();

          expect(
            find.text('Sin permisos para modificar este reporte.'),
            findsOneWidget,
          );
        } finally {
          await session.signOut();
        }
      },
    );
  });
}
