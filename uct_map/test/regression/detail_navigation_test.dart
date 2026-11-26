import 'package:uct_map/domain/entities/professor.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/domain/repositories/schedule_repository.dart';
import 'package:uct_map/presentation/screens/professors/professor_detail_screen.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/campus_map_target.dart';
import 'package:uct_map/presentation/navigation/main_navigation_screen.dart';
import 'package:uct_map/presentation/screens/map/campus_location_screen.dart';
import 'package:uct_map/presentation/screens/map/widgets/campus_map_view.dart';

import '../helpers/mock_mapbox_platform.dart';
import 'session_fixture.dart' as roles;

const campus = {
  'id': 'campus',
  'name': 'Campus de prueba',
  'address': 'Dirección de prueba',
  'coordinates': {'latitude': -38.73, 'longitude': -72.59},
};
const building = {
  'id': 'building',
  'campusId': 'campus',
  'name': 'Biblioteca de prueba',
  'floorsCount': 2,
  'coordinates': {'latitude': -38.73, 'longitude': -72.59},
};
const room = {
  'id': 'room',
  'buildingId': 'building',
  'categoryId': 'category',
  'name': 'Aula de prueba',
  'floor': 2,
};
const structure = {
  'id': 'office',
  'campusId': 'campus',
  'categoryId': 'category',
  'name': 'Atención de prueba',
  'coordinates': {'latitude': -38.735, 'longitude': -72.595},
};
http.Client client({
  bool hasLocation = true,
  bool Function()? locationAvailable,
}) => MockClient((request) async {
  final data = switch (request.url.path) {
    ApiEndpoints.campusList => [campus],
    final path when path == ApiEndpoints.campusDetail('campus') => campus,
    ApiEndpoints.campusBuildingsList => [building],
    final path when path == ApiEndpoints.buildingDetail('building') => building,
    ApiEndpoints.campusBuildingLocationsPath =>
      (locationAvailable?.call() ?? hasLocation)
          ? [
              {
                'id': 'building',
                'name': 'Biblioteca de prueba',
                'location': {'latitude': -38.736, 'longitude': -72.596},
                'metadata': {
                  'campusId': 'campus',
                  'floorsCount': 2,
                  'services': 'Consultas',
                },
              },
            ]
          : [],
    final path when path == ApiEndpoints.buildingRooms('building') => [room],
    ApiEndpoints.campusRooms || ApiEndpoints.campusRoomSearchPath => [room],
    final path when path == ApiEndpoints.roomDetail('room') => room,
    final path when path == ApiEndpoints.structureDetail('office') => structure,
    ApiEndpoints.campusStructureLocationsPath =>
      (locationAvailable?.call() ?? hasLocation)
          ? [
              {
                'id': 'office',
                'name': 'Atención de prueba',
                'location': {'latitude': -38.735, 'longitude': -72.595},
                'metadata': {
                  'campusId': 'campus',
                  'categoryId': 'category',
                  'categoryName': 'Consultas',
                },
              },
            ]
          : [],
    _ => [],
  };
  return http.Response(jsonEncode(data), 200);
});

class _Schedule implements ScheduleRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(setupMockMapboxPlatform);
  for (final search in ['Biblioteca', 'Aula']) {
    testWidgets(
      '$search conserva búsqueda/edificio al regresar de detalle y mapa',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(900, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = SessionController(storage: roles.MemoryStorage());
        await session.ready;
        ApiClientProvider.initialize(session, innerClient: client());
        await tester.pumpWidget(
          MaterialApp(
            home: const MainNavigationScreen(initialIndex: 1),
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();
        final original = tester.state(find.byType(MainNavigationScreen));
        await tester.enterText(find.byType(TextField), search);
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Filtrar'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Biblioteca de prueba').last);
        await tester.pumpAndSettle();
        final result = find.widgetWithText(
          ListTile,
          search == 'Aula' ? 'Aula de prueba' : 'Biblioteca de prueba',
        );
        await tester.scrollUntilVisible(
          result,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(result);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ver en mapa'));
        await tester.pumpAndSettle();
        expect(find.byType(CampusLocationScreen), findsOneWidget);
        final map = tester.widget<CampusMapView>(find.byType(CampusMapView));
        expect(map.campus!.id, 'campus');
        expect(map.buildings.single.id, 'building');
        expect(map.buildings.single.latitude, -38.736);
        if (search == 'Aula') {
          expect(
            tester
                .widget<CampusLocationScreen>(find.byType(CampusLocationScreen))
                .target
                .roomId,
            'room',
          );
        }
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Ver en mapa'), findsOneWidget);
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();
        expect(tester.state(find.byType(MainNavigationScreen)), same(original));
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          search,
        );
        expect(
          tester
              .state<FormFieldState<String>>(
                find.byType(DropdownButtonFormField<String>).first,
              )
              .value,
          'building',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
  }
  testWidgets(
    'detalle docente abre el ID de su atención y regresa al mismo detalle',
    (tester) async {
      final session = await roles.signIn('Student');
      ApiClientProvider.initialize(session, innerClient: client());
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home: ProfessorDetailScreen(
            professor: const Professor(
              id: 'teacher',
              name: 'Docente de prueba',
              department: '',
              office: '',
              email: 'teacher@example.test',
              structureRefId: 'office',
            ),
            repository: _Schedule(),
            locations: const {'office': 'Atención de prueba'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver en Mapa'));
      await tester.tap(find.text('Ver en Mapa'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CampusMapView>(find.byType(CampusMapView))
            .structures
            .single
            .id,
        'office',
      );
      expect(find.textContaining('Ubicando oficina'), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ProfessorDetailScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    },
  );
  for (final hasLocation in [true, false]) {
    testWidgets('estructura por ID y ubicación verificada=$hasLocation', (
      tester,
    ) async {
      var available = hasLocation;
      final session = SessionController(storage: roles.MemoryStorage());
      await session.ready;
      ApiClientProvider.initialize(
        session,
        innerClient: client(locationAvailable: () => available),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: CampusLocationScreen(
            target: CampusMapTarget.structure('office'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (hasLocation) {
        expect(
          tester
              .widget<CampusMapView>(find.byType(CampusMapView))
              .structures
              .single
              .id,
          'office',
        );
      } else {
        expect(find.byType(CampusMapView), findsNothing);
        expect(
          find.textContaining(
            'no tiene una ubicación cartográfica verificable',
          ),
          findsOneWidget,
        );
        available = true;
        await tester.tap(find.text('Reintentar'));
        await tester.pumpAndSettle();
        expect(find.byType(CampusMapView), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
  }
}
