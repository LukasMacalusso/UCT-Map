import '../helpers/mock_mapbox_platform.dart';

import 'dart:async';
import 'dart:convert';

import 'fixture_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/models/lost_object_dto.dart';
import 'package:uct_map/data/models/report_dto.dart';
import 'package:uct_map/main.dart';
import 'package:uct_map/presentation/screens/home/admin_home_screen.dart';
import 'package:uct_map/presentation/screens/home/complaints_officer_home_screen.dart';
import 'package:uct_map/presentation/screens/home/objects_officer_home_screen.dart';
import 'package:uct_map/presentation/screens/lost_objects/lost_objects_screen.dart';
import 'package:uct_map/presentation/screens/tickets/tickets_screen.dart';

import 'session_fixture.dart' as roles;
import 'test_fonts.dart';

List<Map<String, dynamic>> objects = [
  for (final n in [1, 2, 3])
    {
      'title': 'Objeto de prueba $n',
      'description': 'Descripción del objeto',
      'status': n - 1,
      'structureId': 'office',
      'photoUrl': '',
    },
];
Map<String, dynamic> page({bool total = true}) => {
  'items': objects,
  if (total) 'totalCount': 9,
  'page': 1,
  'pageSize': 3,
  'totalPages': 3,
};

List<Map<String, dynamic>> reports = [
  for (final n in [1, 2, 3])
    {
      'id': 'report-$n',
      'structureRefId': 'office',
      'ticketType': n - 1,
      'reportedAt': '2026-11-02T10:00:00Z',
      'isActive': true,
      'complaintDetails': {
        'title': 'Incidente de prueba $n',
        'description': 'Descripción del incidente',
        'status': 0,
      },
    },
];
Map<String, dynamic> reportsPage({bool total = true}) => {
  'items': reports,
  if (total) 'totalCount': 9,
  'page': 1,
  'pageSize': 3,
  'totalPages': 3,
};

void main() {
  group('Inicio de objetos', () {
    setUpAll(() async {
      setupMockMapboxPlatform();
      await loadUiFonts();
    });
    testWidgets(
      'ObjectsOfficer restaura resumen real paginado y conserva bloqueo de IDs',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = await roles.signIn('ObjectsOfficer');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient(
            (r) async => http.Response(
              jsonEncode(r.url.path.contains('lost-objects') ? page() : []),
              200,
            ),
          ),
        );
        debugDisableShadows = false;
        await tester.pumpWidget(
          const RepaintBoundary(
            key: ValueKey('objects-capture'),
            child: UctMapApp(),
          ),
        );
        await tester.pumpAndSettle();
        debugDisableShadows = true;
        expect(find.text('Inicio objetos'), findsOneWidget);
        expect(find.text('9 objetos registrados'), findsOneWidget);
        expect(find.text('3 objetos registrados'), findsNothing);
        expect(find.text('Objeto de prueba 1'), findsOneWidget);
        expect(
          find.textContaining('Hay registros sin identificador'),
          findsOneWidget,
        );
        expect(find.text('Gestionar usuarios'), findsNothing);
        await tester.ensureVisible(find.text('Gestionar objetos'));
        await tester.tap(find.text('Gestionar objetos'));
        await tester.pumpAndSettle();
        expect(find.byType(LostObjectsScreen), findsOneWidget);
        expect(find.textContaining('backend no devuelve el ID'), findsWidgets);
        final buttons = tester.widgetList<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Cambiar Estado'),
        );
        expect(buttons.isNotEmpty, isTrue);
        expect(buttons.every((b) => b.onPressed == null), isTrue);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('9 objetos registrados'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
    testWidgets(
      'ausencia de total no convierte el tamaño de página en un total',
      (tester) async {
        final session = await roles.signIn('ObjectsOfficer');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient(
            (_) async => http.Response(jsonEncode(page(total: false)), 200),
          ),
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: ObjectsOfficerHomeScreen())),
        );
        await tester.pumpAndSettle();
        expect(find.text('Consulta los objetos registrados'), findsOneWidget);
        expect(find.text('3 objetos registrados'), findsNothing);
        expect(
          PaginatedLostObjectsResponse.fromJson(page(total: false))
              .hasTotalCount,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
    testWidgets(
      'otro rol no carga resumen de objetos ni acciones de encargado',
      (tester) async {
        final session = await roles.signIn('Admin');
        var requests = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((_) async {
            requests++;
            return http.Response('{}', 200);
          }),
        );
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: ObjectsOfficerHomeScreen())),
        );
        await tester.pumpAndSettle();
        expect(requests, 0);
        expect(find.text('Gestionar objetos'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
    testWidgets('fallo no es vacío y reintento conserva estados distintos', (
      tester,
    ) async {
      final session = await roles.signIn('ObjectsOfficer');
      var failure = true;
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (_) async => http.Response(
            failure
                ? '{}'
                : jsonEncode({
                    'items': [],
                    'totalCount': 0,
                    'page': 1,
                    'pageSize': 3,
                    'totalPages': 0,
                  }),
            failure ? 500 : 200,
          ),
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ObjectsOfficerHomeScreen())),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo cargar el resumen de objetos.'),
        findsOneWidget,
      );
      expect(find.text('0 objetos registrados'), findsNothing);
      failure = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('0 objetos registrados'), findsOneWidget);
      expect(find.text('No hay objetos registrados.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
    testWidgets('dashboard estrecho con texto al 200 % no desborda', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = await roles.signIn('ObjectsOfficer');
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (_) async => http.Response(jsonEncode(page()), 200),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(body: ObjectsOfficerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Objeto de prueba 3'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
  });

  group('Inicio de incidencias', () {
    setUpAll(() async {
      setupMockMapboxPlatform();
      await loadUiFonts();
    });
    testWidgets(
      'ComplaintsOfficer restaura resumen paginado y abre detalle real por ID',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(430, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = await roles.signIn('ComplaintsOfficer');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient(
            (r) async => http.Response(
              jsonEncode(
                r.url.path.endsWith('/reports')
                    ? reportsPage()
                    : r.url.path.contains('/reports/')
                    ? reports.first
                    : [],
              ),
              200,
            ),
          ),
        );
        debugDisableShadows = false;
        await tester.pumpWidget(
          const RepaintBoundary(
            key: ValueKey('reports-capture'),
            child: UctMapApp(),
          ),
        );
        await tester.pumpAndSettle();
        debugDisableShadows = true;
        expect(find.text('Inicio incidencias'), findsOneWidget);
        expect(find.text('9 reportes registrados'), findsOneWidget);
        expect(find.text('3 reportes registrados'), findsNothing);
        expect(find.text('Incidente de prueba 1'), findsOneWidget);
        expect(find.text('Gestionar usuarios'), findsNothing);
        await tester.tap(find.text('Ver reporte').first);
        await tester.pumpAndSettle();
        expect(find.text('Detalle del Reporte'), findsOneWidget);
        expect(find.text('report-1'), findsOneWidget);
        expect(find.text('Cambiar Estado del Reporte'), findsOneWidget);
        expect(find.text('Ver ubicación'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Gestionar incidentes'));
        await tester.tap(find.text('Gestionar incidentes'));
        await tester.pumpAndSettle();
        expect(find.byType(TicketsScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('9 reportes registrados'), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
    testWidgets(
      'ausencia de total no convierte el tamaño de página en un total',
      (tester) async {
        final session = await roles.signIn('ComplaintsOfficer');
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient(
            (_) async =>
                http.Response(jsonEncode(reportsPage(total: false)), 200),
          ),
        );
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ComplaintsOfficerHomeScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Consulta los reportes registrados'), findsOneWidget);
        expect(find.text('3 reportes registrados'), findsNothing);
        expect(
          PaginatedReportsResponse.fromJson(reportsPage(total: false))
              .hasTotalCount,
          isFalse,
        );
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
    testWidgets(
      'otro rol no carga resumen de incidentes ni acciones de encargado',
      (tester) async {
        final session = await roles.signIn('Admin');
        var requests = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((_) async {
            requests++;
            return http.Response('{}', 200);
          }),
        );
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ComplaintsOfficerHomeScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(requests, 0);
        expect(find.text('Gestionar incidentes'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
    testWidgets('fallo no es vacío y reintento conserva estados distintos', (
      tester,
    ) async {
      final session = await roles.signIn('ComplaintsOfficer');
      var failure = true;
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (_) async => http.Response(
            failure
                ? '{}'
                : jsonEncode({
                    'items': [],
                    'totalCount': 0,
                    'page': 1,
                    'pageSize': 3,
                    'totalPages': 0,
                  }),
            failure ? 500 : 200,
          ),
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ComplaintsOfficerHomeScreen())),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('No se pudo cargar el resumen de incidentes.'),
        findsOneWidget,
      );
      expect(find.text('0 reportes registrados'), findsNothing);
      failure = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('0 reportes registrados'), findsOneWidget);
      expect(find.text('No hay reportes registrados.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
    testWidgets('dashboard estrecho con texto al 200 % no desborda', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = await roles.signIn('ComplaintsOfficer');
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (_) async => http.Response(jsonEncode(reportsPage()), 200),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(body: ComplaintsOfficerHomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Incidente de prueba 3'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
  });

  group('Vistas por rol', () {
    setUpAll(loadUiFonts);
    for (final role in ['Admin', 'ObjectsOfficer', 'ComplaintsOfficer']) {
      testWidgets('$role vacío y texto al 200 %', (tester) async {
        await tester.binding.setSurfaceSize(const Size(390, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = await roles.signIn(role);
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient(
            (r) async => http.Response(
              jsonEncode(
                r.url.path == FixtureRoutes.identity
                    ? []
                    : {
                        'items': [],
                        'totalCount': 0,
                        'page': 1,
                        'pageSize': 3,
                        'totalPages': 0,
                      },
              ),
              200,
            ),
          ),
        );
        final child = switch (role) {
          'Admin' => const AdminHomeScreen(),
          'ObjectsOfficer' => const ObjectsOfficerHomeScreen(),
          _ => const ComplaintsOfficerHomeScreen(),
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF003865),
                primary: const Color(0xFF003865),
                secondary: const Color(0xFFEAA221),
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              appBar: AppBar(title: const Text('Inicio')),
              body: RepaintBoundary(
                key: const ValueKey('capture'),
                child: child,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('0 '), findsWidgets);
        final action = find.text(switch (role) {
          'Admin' => 'Gestionar usuarios',
          'ObjectsOfficer' => 'Gestionar objetos',
          _ => 'Gestionar incidentes',
        });
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      });
    }
  });

  group('Cierre de sesión', () {
    for (final role in ['ObjectsOfficer', 'ComplaintsOfficer']) {
      testWidgets('$role descarta resumen si cierra sesión durante carga', (
        tester,
      ) async {
        final session = await roles.signIn(role);
        final pending = Completer<http.Response>();
        var reads = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((_) {
            reads++;
            return pending.future;
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: role == 'ObjectsOfficer'
                  ? const ObjectsOfficerHomeScreen()
                  : const ComplaintsOfficerHomeScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(reads, 1);
        await session.signOut();
        await tester.pumpAndSettle();
        pending.complete(
          http.Response(
            jsonEncode({
              'items': [],
              'totalCount': 0,
              'page': 1,
              'pageSize': 3,
              'totalPages': 0,
            }),
            200,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('0 objetos'), findsNothing);
        expect(find.textContaining('0 reportes'), findsNothing);
        expect(find.textContaining('Gestionar'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      });
    }
  });
}
