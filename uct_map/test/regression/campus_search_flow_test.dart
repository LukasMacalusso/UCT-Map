import 'dart:async';

import '../helpers/mock_mapbox_platform.dart';

import 'package:uct_map/presentation/widgets/app_navigation_bar.dart';
import 'package:uct_map/core/network/api_endpoints.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/domain/entities/campus.dart';
import 'package:uct_map/presentation/screens/search/search_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/domain/entities/building.dart';
import 'package:uct_map/domain/entities/category.dart';
import 'package:uct_map/domain/entities/campus_search_filter.dart';
import 'package:uct_map/presentation/screens/home/teacher_home_screen.dart';
import 'package:uct_map/presentation/screens/map/widgets/campus_search_sheet.dart';

import 'session_fixture.dart' as roles;

void main() {
  setUpAll(setupMockMapboxPlatform);
  testWidgets(
    'barra común mantiene cinco destinos, sin Perfil, y preserva índices',
    (tester) async {
      var tab = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppNavigationBar(
              currentTab: 5,
              onSelectTab: (value) => tab = value,
            ),
          ),
        ),
      );
      for (final (label, index) in [
        ('Inicio', 5),
        ('Mapa', 0),
        ('Buscar', 1),
        ('Reportes', 3),
        ('Objetos', 2),
      ]) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tab, index);
      }
      expect(find.text('Perfil'), findsNothing);
    },
  );

  testWidgets('campus local persiste y rechaza respuesta del campus anterior', (
    tester,
  ) async {
    final oldBuildings = Completer<http.Response>();
    final session = SessionController(storage: roles.MemoryStorage());
    await session.ready;
    ApiClientProvider.initialize(
      session,
      innerClient: MockClient((request) async {
        if (request.url.path == ApiEndpoints.campusList)
          return http.Response(
            jsonEncode([
              {'id': 'a', 'name': 'Campus A'},
              {'id': 'b', 'name': 'Campus B'},
            ]),
            200,
          );
        if (request.url.path == ApiEndpoints.campusBuildingsList &&
            request.url.queryParameters['campusId'] == 'a')
          return oldBuildings.future;
        return http.Response('[]', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: const SearchScreen())),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(PopupMenuButton<Campus>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<Campus>, 'Campus B'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    oldBuildings.complete(http.Response('[]', 200));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PopupMenuButton<Campus>>(find.byType(PopupMenuButton<Campus>))
          .initialValue!
          .id,
      'b',
    );
    expect(find.byTooltip('Cambiar campus: Campus B'), findsOneWidget);
    expect(find.text('Campus B'), findsNothing);
    expect(find.byTooltip('Ver categorías de espacios'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    ApiClientProvider.reset();
    session.dispose();
  });

  test('filtros combinados no atribuyen categoría a edificios ni edificio a servicios', () {
    const f = CampusSearchFilter(buildingId: 'b', categoryId: 'c');
    expect(f.matches(building: 'b', category: 'c'), isTrue);
    expect(f.matches(building: 'b'), isFalse);
    expect(f.matches(category: 'c'), isFalse);
    expect(f.matches(building: 'other', category: 'c'), isFalse);
    expect(const CampusSearchFilter().matches(), isTrue);
  });
  testWidgets(
    'Teacher restaura su dashboard y abre agenda independiente; Student no accede',
    (tester) async {
      final session = await roles.signIn('Teacher');
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient((_) async => http.Response('[]', 200)),
      );
      String? destination;
      await tester.pumpWidget(
        MaterialApp(
          home: const SessionLandingScreen(),
          onGenerateRoute: (s) {
            destination = s.name;
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Agenda separada')),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inicio docente'), findsOneWidget);
      expect(find.text('Ver mis citas'), findsNothing);
      await tester.tap(find.text('Ver mi agenda'));
      await tester.pumpAndSettle();
      expect(destination, AppRoutes.teacherSchedule);
      expect(find.text('Agenda separada'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
      final student = await roles.signIn('Student');
      ApiClientProvider.initialize(student);
      await tester.pumpWidget(const MaterialApp(home: TeacherHomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Inicio docente'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      student.dispose();
    },
  );
  testWidgets('edificio y categoría filtran sin perder el texto al limpiar', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const buildings = [
      Building(
        id: 'a',
        campusId: 'campus',
        name: 'Edificio A',
        floorsCount: 1,
        latitude: 1,
        longitude: 2,
      ),
      Building(
        id: 'b',
        campusId: 'campus',
        name: 'Edificio B',
        floorsCount: 1,
        latitude: 1,
        longitude: 2,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusSearchSheet(
            buildings: buildings,
            structures: const [],
            embedded: true,
            loadCategories: () async => const [
              Category(id: 'x', name: 'Laboratorio', icon: '', description: ''),
              Category(id: 'y', name: 'Oficina', icon: '', description: ''),
            ],
            searchRooms: (_) async => [
              {
                'id': 'one',
                'buildingId': 'a',
                'name': 'Consulta A',
                'categoryId': 'x',
                'floor': 1,
              },
              {
                'id': 'two',
                'buildingId': 'b',
                'name': 'Consulta B',
                'categoryId': 'y',
                'floor': 1,
              },
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Filtrar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Consulta');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('Consulta A'), findsOneWidget);
    expect(find.text('Consulta B'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edificio A').last);
    await tester.pumpAndSettle();
    expect(find.text('Consulta A'), findsOneWidget);
    expect(find.text('Consulta B'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oficina').last);
    await tester.pumpAndSettle();
    expect(find.text('No se encontraron resultados.'), findsOneWidget);
    await tester.tap(find.text('Limpiar filtros'));
    await tester.pumpAndSettle();
    expect(find.text('Consulta A'), findsOneWidget);
    expect(find.text('Consulta B'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Consulta',
    );
  });
}
