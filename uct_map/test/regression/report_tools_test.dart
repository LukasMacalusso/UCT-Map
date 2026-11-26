import '../helpers/mock_mapbox_platform.dart';

import 'dart:convert';

import 'fixture_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/heatmaps/load_heatmap.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/data/models/report_dto.dart';
import 'package:uct_map/domain/entities/campus.dart';
import 'package:uct_map/domain/entities/ticket.dart';
import 'package:uct_map/domain/repositories/campus_repository.dart';
import 'package:uct_map/domain/repositories/lost_objects_repository.dart';
import 'package:uct_map/domain/repositories/reports_repository.dart';
import 'package:uct_map/presentation/screens/tickets/create_ticket_screen.dart';

import 'session_fixture.dart' show MemoryStorage, account;

class Reports implements ReportsRepository {
  final pages = <int>[];
  @override
  Future<PaginatedReportsResponse> getReports({
    ReportFilterParams? filter,
  }) async {
    final page = filter!.page;
    pages.add(page);
    Ticket ticket(String id, bool complaint) => Ticket(
      id: id,
      userRefId: 'author',
      structureRefId: 'place',
      ticketType: TicketStatus.pending,
      isActive: true,
      reportedAt: DateTime(2026),
      complaintDetails: complaint
          ? const ComplaintDetails(title: 'Incidencia', description: 'Real')
          : null,
      lostObjectId: complaint ? null : 'object',
    );
    return PaginatedReportsResponse(
      items: page == 1
          ? [ticket('r1', true), ticket('object-ticket', false)]
          : [ticket('r2', true)],
      totalCount: 3,
      page: page,
      pageSize: 2,
      totalPages: 2,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Objects implements LostObjectsRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Campus implements CampusRepository {
  @override
  Future<List<Campus>> getCampuses() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Mapas de calor', () {
    setUpAll(setupMockMapboxPlatform);
    test('heatmap pagina completamente y no cuenta tickets sin queja como incidencias', () async {
      final repo = Reports();
      final counts = await loadHeatmapCounts(
        objectsMode: false,
        reports: repo,
        objects: Objects(),
        checkSession: () {},
      );
      expect(repo.pages, [1, 2]);
      expect(counts, {'place': 2});
    });
    for (final role in [
      'Student',
      'Teacher',
      'ObjectsOfficer',
      'ComplaintsOfficer',
      'Admin',
    ]) {
      for (final objectsMode in [false, true]) {
        final allowed =
            role == 'Admin' ||
            (objectsMode
                ? role == 'ObjectsOfficer'
                : role == 'ComplaintsOfficer');
        testWidgets(
          '$role ${allowed ? 'accede' : 'no accede'} al heatmap ${objectsMode ? 'objetos' : 'incidencias'}',
          (tester) async {
            final session = SessionController(storage: MemoryStorage());
            await session.ready;
            await account(session, 'test', role);
            final paths = <String>[];
            ApiClientProvider.initialize(
              session,
              innerClient: MockClient((request) async {
                final path = request.url.path;
                paths.add(path);
                if (path == ApiEndpoints.campusList)
                  return http.Response(
                    jsonEncode([
                      {
                        'id': 'c',
                        'name': 'Campus',
                        'latitude': -38.7,
                        'longitude': -72.6,
                      },
                    ]),
                    200,
                  );
                if (path.startsWith(FixtureRoutes.campusPrefix))
                  return http.Response('[]', 200);
                return http.Response(
                  jsonEncode({
                    'items': [],
                    'page': 1,
                    'pageSize': 10,
                    'totalPages': 0,
                    'totalCount': 0,
                  }),
                  200,
                );
              }),
            );
            final route = objectsMode
                ? AppRoutes.objectHeatmap
                : AppRoutes.reportHeatmap;
            await tester.pumpWidget(
              MaterialApp(
                onGenerateRoute: AppRoutes.onGenerateRoute,
                onGenerateInitialRoutes: (_) => [
                  AppRoutes.onGenerateRoute(RouteSettings(name: route)),
                ],
              ),
            );
            await tester.pumpAndSettle();
            final incidentPaths = paths
                .where((p) => p.startsWith(FixtureRoutes.incidentPrefix))
                .toList();
            expect(
              incidentPaths,
              allowed
                  ? [
                      objectsMode
                          ? ApiEndpoints.incidentLostObjects
                          : ApiEndpoints.incidentReports,
                    ]
                  : isEmpty,
            );
            expect(find.byTooltip('Crear campus'), findsNothing);
            expect(find.text('Edificios'), findsNothing);
            if (allowed)
              expect(
                find.text('No hay registros con ubicación en este campus.'),
                findsOneWidget,
              );
            if (role != 'Admin')
              expect(find.byType(SegmentedButton<bool>), findsNothing);
            await tester.pumpWidget(const SizedBox());
            session.dispose();
            ApiClientProvider.reset();
          },
        );
      }
    }
  });

  group('Formulario accesible', () {
    testWidgets(
      'formulario en320px y200% permite leer encabezado y usar interruptor sin recortes',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = SessionController(storage: MemoryStorage());
        await session.ready;
        await account(session, 'student', 'Student');
        ApiClientProvider.initialize(session);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: CreateTicketScreen(
              repository: Reports(),
              campusRepository: _Campus(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.byType(Switch),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final heading = find.text('Detalles de la Queja / Reclamo');
        expect(tester.getRect(heading).right, lessThanOrEqualTo(320));
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Token JWT'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
        ApiClientProvider.reset();
      },
    );
  });
}
