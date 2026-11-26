import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/core/network/problem_details.dart';
import 'package:uct_map/data/datasources/campus_remote_ds.dart';
import 'package:uct_map/data/models/lost_object_dto.dart';
import 'package:uct_map/data/models/report_dto.dart';
import 'package:uct_map/data/storage/pending_object_storage.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/entities/lost_object.dart';
import 'package:uct_map/domain/entities/ticket.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/domain/repositories/lost_objects_repository.dart';
import 'package:uct_map/domain/repositories/reports_repository.dart';
import 'package:uct_map/presentation/screens/lost_objects/create_lost_object_screen.dart';
import 'package:uct_map/presentation/screens/lost_objects/lost_object_detail_screen.dart';
import 'package:uct_map/presentation/screens/lost_objects/lost_objects_screen.dart';
import 'package:uct_map/presentation/screens/profile/my_lost_items_screen.dart';

const _structureA = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';
const _structureB = 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e';
const _structureOtherCampus = 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f';
const _userId = '11111111-1111-1111-1111-111111111111';

class _MemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> clear() async => _token = null;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;
}

class _MemoryPendingStorage implements PendingObjectStorage {
  final Map<String, PendingObject> values = {};

  @override
  Future<void> clear(String userId) async => values.remove(userId);

  @override
  Future<PendingObject?> read(String userId) async => values[userId];

  @override
  Future<void> save(String userId, PendingObject item) async {
    values[userId] = item;
  }
}

Future<SessionController> _signInWithRole(String role) async {
  final session = SessionController(storage: _MemoryTokenStorage());
  await session.ready;
  final payload = {
    'sub': _userId,
    'email': 'tester@uct.cl',
    'role': role,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
        1000,
    'iss': 'https://identity-api',
    'aud': 'api-gateway',
  };
  String enc(Object json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  await session.signInReal(
    AuthLoginResult(
      userId: _userId,
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

    if (path.endsWith('/campuses/campus-sf')) {
      return http.Response(
        jsonEncode({
          'id': 'campus-sf',
          'name': 'Campus San Francisco',
          'address': 'Manuel Montt 56',
          'latitude': -38.736,
          'longitude': -72.590,
        }),
        200,
      );
    }

    if (path.endsWith('/buildings/locations')) {
      return http.Response(
        jsonEncode([
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
        ]),
        200,
      );
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
      return http.Response(
        jsonEncode([
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
        ]),
        200,
      );
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

    if (path.endsWith('/structures/$_structureOtherCampus')) {
      return http.Response(
        jsonEncode({
          'id': _structureOtherCampus,
          'name': 'Casino San Francisco',
          'campusId': 'campus-sf',
          'categoryId': 'cat-2',
          'latitude': -38.736,
          'longitude': -72.590,
        }),
        200,
      );
    }

    return http.Response('Not Found', 404);
  }),
);

class _StatefulLostObjectsRepo implements LostObjectsRepository {
  _StatefulLostObjectsRepo(List<LostObject> initial) : items = List.of(initial);

  final List<LostObject> items;
  final List<LostObjectFilterParams?> receivedFilters = [];
  final List<CreateLostObjectDto> createdDtos = [];
  final List<({String id, LostObjectStatus status})> statusUpdates = [];
  final List<String> deletedIds = [];
  bool failNextGetById404 = false;
  Object? nextUpdateError;
  int _nextId = 100;

  @override
  Future<CreateLostObjectResponse> createLostObject(
    CreateLostObjectDto dto,
  ) async {
    dto.validate();
    createdDtos.add(dto);
    final id = '671fb2c58971f49673980${_nextId++}';
    items.insert(
      0,
      LostObject(
        id: id,
        title: dto.title.trim(),
        description: dto.description.trim(),
        status: dto.status,
        photoUrl: dto.photoUrl.trim(),
        structureId: dto.structureId.trim(),
        date: DateTime(2026, 11, 26, 14, 0),
      ),
    );
    return CreateLostObjectResponse(id: id);
  }

  @override
  Future<LostObject> getLostObjectById(String id) async {
    if (failNextGetById404) {
      failNextGetById404 = false;
      throw const ApiException('Not found', 404);
    }
    final match = items.where((o) => o.id == id);
    if (match.isEmpty) {
      throw const ApiException('Not found', 404);
    }
    return match.first;
  }

  @override
  Future<PaginatedLostObjectsResponse> getLostObjects({
    LostObjectFilterParams? filter,
  }) async {
    receivedFilters.add(filter);
    final f = filter ?? const LostObjectFilterParams();
    var filtered = List<LostObject>.of(items);

    if (f.title != null && f.title!.trim().isNotEmpty) {
      final q = f.title!.trim().toLowerCase();
      filtered = filtered
          .where((o) => o.title.toLowerCase().contains(q))
          .toList();
    }
    if (f.structureId != null && f.structureId!.trim().isNotEmpty) {
      filtered = filtered
          .where((o) => o.structureId == f.structureId!.trim())
          .toList();
    }
    if (f.status != null) {
      filtered = filtered.where((o) => o.status == f.status).toList();
    }

    filtered.sort((a, b) {
      int cmp;
      switch (f.sortBy) {
        case 'Title':
          cmp = a.title.compareTo(b.title);
          break;
        case 'Status':
          cmp = a.status.value.compareTo(b.status.value);
          break;
        default:
          cmp = (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000));
      }
      return f.descending ? -cmp : cmp;
    });

    final totalCount = filtered.length;
    final totalPages = totalCount == 0 ? 0 : (totalCount / f.pageSize).ceil();
    final start = (f.page - 1) * f.pageSize;
    final pageItems = start >= totalCount
        ? <LostObject>[]
        : filtered.skip(start).take(f.pageSize).toList();

    return PaginatedLostObjectsResponse(
      items: pageItems,
      totalCount: totalCount,
      page: f.page,
      pageSize: f.pageSize,
      totalPages: totalPages,
    );
  }

  @override
  Future<void> updateStatus(String id, LostObjectStatus newStatus) async {
    if (nextUpdateError != null) {
      final err = nextUpdateError!;
      nextUpdateError = null;
      throw err;
    }
    statusUpdates.add((id: id, status: newStatus));
    final idx = items.indexWhere((o) => o.id == id);
    if (idx == -1) throw const ApiException('Not found', 404);
    items[idx] = items[idx].copyWith(status: newStatus);
  }

  @override
  Future<void> deleteLostObject(String id) async {
    deletedIds.add(id);
    items.removeWhere((o) => o.id == id);
  }
}

class _StatefulReportsRepo implements ReportsRepository {
  _StatefulReportsRepo(List<Ticket> initial) : items = List.of(initial);

  final List<Ticket> items;
  final List<CreateReportDto> createdReports = [];
  bool failNextCreate = false;
  int _nextId = 1;

  @override
  Future<CreateReportResponse> createReport(CreateReportDto dto) async {
    if (failNextCreate) {
      failNextCreate = false;
      throw const NetworkException('Fallo temporal de red');
    }
    createdReports.add(dto);
    final id = 'rep-${_nextId++}';
    items.add(
      Ticket(
        id: id,
        userRefId: _userId,
        structureRefId: dto.structureRefId,
        ticketType: dto.ticketType,
        isActive: dto.isActive,
        reportedAt: dto.reportedAt ?? DateTime(2026, 11, 26),
        lostObjectId: dto.lostObjectId,
        complaintDetails: dto.complaint == null
            ? null
            : ComplaintDetails(
                title: dto.complaint!.title,
                description: dto.complaint!.description,
                status: dto.complaint!.status,
              ),
      ),
    );
    return CreateReportResponse(id: id);
  }

  @override
  Future<void> deleteReport(String id) async {
    items.removeWhere((r) => r.id == id);
  }

  @override
  Future<Ticket> getReportById(String id) async =>
      items.firstWhere((r) => r.id == id);

  @override
  Future<PaginatedReportsResponse> getReports({
    ReportFilterParams? filter,
  }) async {
    final f = filter ?? const ReportFilterParams();
    var filtered = List<Ticket>.of(items);
    if (f.userRefId != null && f.userRefId!.isNotEmpty) {
      filtered = filtered.where((r) => r.userRefId == f.userRefId).toList();
    }
    if (f.lostObjectId != null && f.lostObjectId!.isNotEmpty) {
      filtered = filtered
          .where((r) => r.lostObjectId == f.lostObjectId)
          .toList();
    }
    final totalCount = filtered.length;
    final totalPages = totalCount == 0 ? 0 : (totalCount / f.pageSize).ceil();
    final start = (f.page - 1) * f.pageSize;
    final pageItems = start >= totalCount
        ? <Ticket>[]
        : filtered.skip(start).take(f.pageSize).toList();
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
  }) async {}
}

LostObject _makeObject({
  required String id,
  required String title,
  String description = 'Descripción detallada del objeto encontrado',
  LostObjectStatus status = LostObjectStatus.pending,
  String structureId = _structureA,
  String photoUrl = '',
  DateTime? date,
}) => LostObject(
  id: id,
  title: title,
  description: description,
  status: status,
  photoUrl: photoUrl,
  structureId: structureId,
  date: date ?? DateTime(2026, 11, 20, 10, 30),
);

void main() {
  group('1. Entidad y DTO de objetos', () {
    test(
      'LostObject.fromJson parsea lostObjectId y fechas ISO y formato .NET',
      () {
        final isoObj = LostObject.fromJson({
          'lostObjectId': '671fb2c58971f49673981234',
          'title': 'Botella azul',
          'description': 'Botella metálica en Biblioteca',
          'date': '2026-11-26T15:30:00Z',
          'status': 'In_Process',
          'photoUrl': 'https://storage.uct.cl/botella.jpg',
          'structureId': _structureA,
        });
        expect(isoObj.id, '671fb2c58971f49673981234');
        expect(isoObj.status, LostObjectStatus.inProcess);
        expect(isoObj.date, isNotNull);

        final dotNetObj = LostObject.fromJson({
          'lostObjectId': '671fb2c58971f49673981235',
          'title': 'Paraguas negro',
          'description': 'Encontrado en Edificio C',
          'date': '11/26/2026 3:45:00 PM',
          'status': 'Resolved',
          'photoUrl': 'https://storage.uct.cl/paraguas.jpg',
          'structureId': _structureB,
        });
        expect(dotNetObj.id, '671fb2c58971f49673981235');
        expect(dotNetObj.status, LostObjectStatus.resolved);
        expect(dotNetObj.date, isNotNull);
        expect(dotNetObj.date!.year, 2026);
        expect(dotNetObj.date!.month, 11);
        expect(dotNetObj.date!.day, 26);
      },
    );

    test(
      'PaginatedLostObjectsResponse calcula totalPages cuando el JSON no lo incluye',
      () {
        final empty = PaginatedLostObjectsResponse.fromJson({
          'items': [],
          'totalCount': 0,
          'page': 1,
          'pageSize': 10,
        });
        expect(empty.totalPages, 0);
        expect(empty.hasNextPage, isFalse);

        final multi = PaginatedLostObjectsResponse.fromJson({
          'items': [],
          'totalCount': 23,
          'page': 1,
          'pageSize': 10,
        });
        expect(multi.totalPages, 3);
        expect(multi.hasNextPage, isTrue);
      },
    );
  });

  group('2. Caso de uso: Creación de objetos', () {
    testWidgets(
      'Student crea objeto con estado Pending forzado y vincula reporte automáticamente',
      (tester) async {
        final session = await _signInWithRole('Student');
        final objectsRepo = _StatefulLostObjectsRepo([]);
        final reportsRepo = _StatefulReportsRepo([]);
        final storage = _MemoryPendingStorage();

        await tester.pumpWidget(
          MaterialApp(
            home: CreateLostObjectScreen(
              repository: objectsRepo,
              reportsRepository: reportsRepo,
              campusRepository: _campusFixture(),
              publicationStorage: storage,
              initialCampusId: 'campus-jp2',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Student no debe ver selector de estado inicial
        expect(find.text('Estado inicial'), findsNothing);

        // Validar formulario con datos inválidos
        await tester.enterText(find.byType(TextFormField).at(0), 'Ab');
        await tester.enterText(find.byType(TextFormField).at(1), 'Cort');
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'foto-sin-protocolo.jpg',
        );
        final submitBtn = find.byType(ElevatedButton);
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(
          find.text('El título debe tener al menos 3 caracteres.'),
          findsOneWidget,
        );
        expect(
          find.text('La descripción debe tener al menos 5 caracteres.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Ingresa una URL absoluta válida (debe empezar con http:// o https://).',
          ),
          findsOneWidget,
        );

        // Completar datos válidos
        final locationPicker = find
            .byType(DropdownButtonFormField<String>)
            .last;
        await tester.ensureVisible(find.byType(TextFormField).at(0));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Llaves con llavero azul',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Encontradas en mesón de biblioteca',
        );
        await tester.ensureVisible(locationPicker);
        await tester.pumpAndSettle();
        await tester.tap(locationPicker);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Biblioteca').last);
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextFormField).at(2),
          'https://storage.uct.cl/llaves.jpg',
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(objectsRepo.createdDtos, hasLength(1));
        expect(objectsRepo.createdDtos.first.status, LostObjectStatus.pending);
        expect(objectsRepo.createdDtos.first.structureId, _structureA);
        expect(reportsRepo.createdReports, hasLength(1));
        expect(
          reportsRepo.createdReports.first.lostObjectId,
          objectsRepo.items.first.id,
        );
        expect(storage.values, isEmpty);

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );

    testWidgets(
      'ObjectsOfficer puede elegir estado inicial y reanudar vínculo pendiente si falla el reporte',
      (tester) async {
        final session = await _signInWithRole('ObjectsOfficer');
        final objectsRepo = _StatefulLostObjectsRepo([]);
        final reportsRepo = _StatefulReportsRepo([])..failNextCreate = true;
        final storage = _MemoryPendingStorage();

        await tester.pumpWidget(
          MaterialApp(
            home: CreateLostObjectScreen(
              repository: objectsRepo,
              reportsRepository: reportsRepo,
              campusRepository: _campusFixture(),
              publicationStorage: storage,
              initialCampusId: 'campus-jp2',
              initialLocationId: _structureA,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ObjectsOfficer sí ve selector de estado inicial
        expect(find.text('Estado inicial'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField).at(0),
          'Audífonos Sony',
        );
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Color negro en estuche rígido',
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'https://storage.uct.cl/audifonos.jpg',
        );
        await tester.pumpAndSettle();

        // Cambiar estado inicial a En Proceso (1)
        final statusDropdown = find.byType(DropdownButton<LostObjectStatus>);
        await tester.ensureVisible(statusDropdown);
        await tester.tap(statusDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('En Proceso (1)').last);
        await tester.pumpAndSettle();

        // Primer envío: crea objeto pero falla el reporte vinculado
        final submitBtn = find.byType(ElevatedButton);
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(objectsRepo.createdDtos, hasLength(1));
        expect(
          objectsRepo.createdDtos.first.status,
          LostObjectStatus.inProcess,
        );
        expect(find.text('Completar vínculo pendiente'), findsOneWidget);
        expect(storage.values[_userId], isNotNull);

        // Reanudar vínculo pendiente sin duplicar objeto
        final resumeBtn = find.text('Completar vínculo pendiente');
        await tester.ensureVisible(resumeBtn);
        await tester.tap(resumeBtn);
        await tester.pumpAndSettle();

        expect(objectsRepo.createdDtos, hasLength(1));
        expect(reportsRepo.createdReports, hasLength(1));
        expect(storage.values, isEmpty);

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );
  });

  group('3. Caso de uso: Búsqueda, filtros, ordenamiento y paginación', () {
    testWidgets(
      'Filtra por título, estado, ubicación/campus, limpia filtros y ordena con showAppBar=false',
      (tester) async {
        final session = await _signInWithRole('Student');
        final repo = _StatefulLostObjectsRepo([
          _makeObject(
            id: 'obj-1',
            title: 'Mochila negra',
            status: LostObjectStatus.pending,
            structureId: _structureA,
            date: DateTime(2026, 11, 20),
          ),
          _makeObject(
            id: 'obj-2',
            title: 'Calculadora Casio',
            status: LostObjectStatus.resolved,
            structureId: _structureOtherCampus,
            date: DateTime(2026, 11, 25),
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: LostObjectsScreen(
              repository: repo,
              campusRepository: _campusFixture(),
              showAppBar: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mochila negra'), findsOneWidget);
        expect(find.text('Calculadora Casio'), findsOneWidget);
        expect(find.textContaining('Biblioteca'), findsOneWidget);

        // Con showAppBar=false el botón de ordenamiento sigue accesible
        final sortBtn = find.byTooltip('Ordenar');
        expect(sortBtn, findsOneWidget);
        await tester.tap(sortBtn);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Título'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();
        expect(repo.receivedFilters.last?.sortBy, 'Title');

        // Búsqueda por título con debounce y botón limpiar inmediato
        await tester.enterText(find.byType(TextField), 'Mochila');
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();
        expect(find.text('Mochila negra'), findsOneWidget);
        expect(find.text('Calculadora Casio'), findsNothing);

        final clearBtn = find.byIcon(Icons.clear);
        expect(clearBtn, findsOneWidget);
        await tester.tap(clearBtn);
        await tester.pumpAndSettle();
        expect(find.text('Calculadora Casio'), findsOneWidget);

        // Filtro por chip de estado
        await tester.tap(find.text('Resueltos'));
        await tester.pumpAndSettle();
        expect(find.text('Calculadora Casio'), findsOneWidget);
        expect(find.text('Mochila negra'), findsNothing);

        // Filtro por campus JP2 combinado con Resueltos -> estado vacío
        await tester.tap(find.byTooltip('Filtrar ubicación'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Campus San Juan Pablo II').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();

        expect(find.text('No se encontraron objetos'), findsOneWidget);
        expect(find.text('Campus San Juan Pablo II'), findsOneWidget);

        // Limpiar Filtros debe limpiar también el filtro de campus
        await tester.tap(find.text('Limpiar Filtros'));
        await tester.pumpAndSettle();
        expect(find.text('Todos los campus'), findsOneWidget);
        expect(find.text('Mochila negra'), findsOneWidget);
        expect(find.text('Calculadora Casio'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );

    testWidgets(
      'Navega entre páginas y hace clamping si la página actual queda vacía',
      (tester) async {
        final session = await _signInWithRole('Student');
        final initial = List.generate(
          11,
          (i) => _makeObject(
            id: 'obj-${i + 1}',
            title: 'Objeto ${(i + 1).toString().padLeft(2, '0')}',
            date: DateTime(2026, 11, 25).subtract(Duration(hours: i)),
          ),
        );
        final repo = _StatefulLostObjectsRepo(initial);

        await tester.pumpWidget(
          MaterialApp(
            home: LostObjectsScreen(
              repository: repo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Desplazar hasta la barra de paginación y avanzar a página 2
        await tester.scrollUntilVisible(
          find.text('Siguiente'),
          600,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Página 1 de 2'), findsOneWidget);

        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text('Objeto 11'), findsOneWidget);
        expect(find.textContaining('Página 2 de 2'), findsOneWidget);

        // Simular eliminación del último ítem (página 2 queda vacía) y refrescar
        repo.items.removeWhere((o) => o.id == 'obj-11');
        await tester.tap(find.byTooltip('Actualizar'));
        await tester.pumpAndSettle();

        // Debe hacer clamping automático a página 1
        expect(find.text('Objeto 01'), findsOneWidget);
        expect(find.text('No se encontraron objetos'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );
  });

  group('4. Caso de uso: Detalle de objeto', () {
    testWidgets(
      'Muestra 404 con reintento, ubicación resuelta y oculta gestión a Student',
      (tester) async {
        final session = await _signInWithRole('Student');
        final repo = _StatefulLostObjectsRepo([
          _makeObject(
            id: 'obj-detail-1',
            title: 'Cuaderno de Cálculo',
            description: 'Tapa dura con espiral rojo',
            status: LostObjectStatus.inProcess,
            structureId: _structureA,
            date: DateTime(2026, 11, 22),
          ),
        ])..failNextGetById404 = true;

        await tester.pumpWidget(
          MaterialApp(
            home: LostObjectDetailScreen(
              objectId: 'obj-detail-1',
              repository: repo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Este objeto ya no está disponible.'), findsOneWidget);

        // Reintentar carga
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();

        expect(find.text('Cuaderno de Cálculo'), findsOneWidget);
        expect(find.text('Tapa dura con espiral rojo'), findsOneWidget);
        expect(find.text('En Proceso'), findsOneWidget);
        expect(
          find.text('Biblioteca · Campus San Juan Pablo II'),
          findsOneWidget,
        );
        expect(find.text('22/11/2026'), findsOneWidget);

        // Student no puede cambiar estado ni eliminar
        expect(find.text('Cambiar Estado del Objeto'), findsNothing);
        expect(find.text('Eliminar objeto'), findsNothing);

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );

    testWidgets(
      'ObjectsOfficer puede cambiar estado desde detalle y propaga actualización al listado',
      (tester) async {
        final session = await _signInWithRole('ObjectsOfficer');
        final repo = _StatefulLostObjectsRepo([
          _makeObject(
            id: 'obj-manage-1',
            title: 'Chaqueta impermeable',
            status: LostObjectStatus.pending,
            structureId: _structureA,
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: LostObjectsScreen(
              repository: repo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Entrar al detalle
        await tester.tap(find.text('Ver detalle'));
        await tester.pumpAndSettle();

        expect(find.text('Detalle del objeto'), findsOneWidget);
        expect(find.text('Cambiar Estado del Objeto'), findsOneWidget);
        expect(find.text('Eliminar objeto'), findsOneWidget);

        // Abrir selector de estado
        await tester.tap(find.text('Cambiar Estado del Objeto'));
        await tester.pumpAndSettle();

        // Guardar Cambios deshabilitado si no se cambia el estado
        final saveBtn = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Guardar Cambios'),
        );
        expect(saveBtn.onPressed, isNull);

        // Seleccionar Resuelto y guardar
        await tester.tap(find.widgetWithText(ChoiceChip, 'Resuelto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guardar Cambios'));
        await tester.pumpAndSettle();

        expect(repo.statusUpdates, hasLength(1));
        expect(repo.statusUpdates.first.status, LostObjectStatus.resolved);
        expect(find.text('Resuelto'), findsOneWidget);

        // Volver al listado -> debe reflejar estado Resuelto
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Estado: Resuelto'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );
  });

  group('5. Caso de uso: Seguimiento de objetos', () {
    testWidgets(
      'MyLostItemsScreen muestra objetos vinculados, aviso de no disponibles, filtra por estado y abre detalle',
      (tester) async {
        final session = await _signInWithRole('Student');
        final objectsRepo = _StatefulLostObjectsRepo([
          _makeObject(
            id: 'obj-track-1',
            title: 'Termo Stanley',
            status: LostObjectStatus.pending,
            structureId: _structureA,
          ),
          _makeObject(
            id: 'obj-track-2',
            title: 'Tarjeta TNE',
            status: LostObjectStatus.resolved,
            structureId: _structureA,
          ),
        ]);
        final reportsRepo = _StatefulReportsRepo([
          Ticket(
            id: 'rep-1',
            userRefId: _userId,
            structureRefId: _structureA,
            ticketType: TicketStatus.pending,
            isActive: true,
            reportedAt: DateTime(2026, 11, 20),
            lostObjectId: 'obj-track-1',
          ),
          Ticket(
            id: 'rep-2',
            userRefId: _userId,
            structureRefId: _structureA,
            ticketType: TicketStatus.resolved,
            isActive: true,
            reportedAt: DateTime(2026, 11, 21),
            lostObjectId: 'obj-track-2',
          ),
          Ticket(
            id: 'rep-3',
            userRefId: _userId,
            structureRefId: _structureA,
            ticketType: TicketStatus.pending,
            isActive: true,
            reportedAt: DateTime(2026, 11, 22),
            lostObjectId: 'obj-deleted-404',
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: MyLostItemsScreen(
              reportsRepository: reportsRepo,
              objectsRepository: objectsRepo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('2 objetos disponibles vinculados a tus reportes'),
          findsOneWidget,
        );
        expect(
          find.text('1 objetos vinculados ya no están disponibles.'),
          findsOneWidget,
        );
        expect(find.text('Termo Stanley'), findsOneWidget);
        expect(find.text('Tarjeta TNE'), findsOneWidget);

        // Filtrar por estado Resuelto
        await tester.tap(find.byType(DropdownButtonFormField<LostObjectStatus?>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Resuelto').last);
        await tester.pumpAndSettle();

        expect(find.text('Tarjeta TNE'), findsOneWidget);
        expect(find.text('Termo Stanley'), findsNothing);

        // Abrir detalle y verificar indicador de vínculo
        await tester.tap(find.text('Tarjeta TNE'));
        await tester.pumpAndSettle();
        expect(find.text('Vinculado a uno de tus reportes.'), findsOneWidget);
        expect(
          find.text('Biblioteca · Campus San Juan Pablo II'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );

    testWidgets(
      'ObjectsOfficer cambia estado desde listado y recibe feedback ante error RFC 7807',
      (tester) async {
        final session = await _signInWithRole('ObjectsOfficer');
        final repo = _StatefulLostObjectsRepo([
          _makeObject(
            id: 'obj-list-status',
            title: 'Cargador MacBook',
            status: LostObjectStatus.pending,
            structureId: _structureA,
          ),
        ]);

        await tester.pumpWidget(
          MaterialApp(
            home: LostObjectsScreen(
              repository: repo,
              campusRepository: _campusFixture(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Abrir diálogo de cambio de estado desde tarjeta
        final changeStatusBtn = find.text('Cambiar Estado');
        await tester.ensureVisible(changeStatusBtn);
        await tester.pumpAndSettle();
        await tester.tap(changeStatusBtn);
        await tester.pumpAndSettle();

        // Tocar el estado actual (Pendiente) no debe disparar PATCH
        await tester.tap(find.widgetWithText(ListTile, 'Pendiente').first);
        await tester.pumpAndSettle();
        expect(repo.statusUpdates, isEmpty);

        // Seleccionar En Proceso -> actualiza correctamente
        await tester.tap(find.widgetWithText(ListTile, 'En Proceso').first);
        await tester.pumpAndSettle();
        expect(repo.statusUpdates, hasLength(1));
        expect(repo.statusUpdates.first.status, LostObjectStatus.inProcess);
        expect(find.text('Estado: En Proceso'), findsOneWidget);

        // Simular error ProblemDetails al intentar cambiar a Resuelto
        repo.nextUpdateError = ProblemDetailsException(
          const ProblemDetails(
            status: 400,
            title: 'Estado inválido',
            detail: 'No se pudo aplicar la transición de estado.',
          ),
        );
        await tester.ensureVisible(changeStatusBtn);
        await tester.pumpAndSettle();
        await tester.tap(changeStatusBtn);
        await tester.pumpAndSettle();
        final resolvedTile = find.widgetWithText(ListTile, 'Resuelto').first;
        await tester.ensureVisible(resolvedTile);
        await tester.pumpAndSettle();
        await tester.tap(resolvedTile);
        await tester.pumpAndSettle();

        expect(
          find.text('No se pudo aplicar la transición de estado.'),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );
  });
}
