import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/data/models/campus_location_dto.dart';
import 'package:uct_map/domain/entities/building.dart';
import 'package:uct_map/presentation/screens/map/widgets/campus_search_sheet.dart';

void main() {
  testWidgets('al pulsar una categoría dos veces se ocultan los resultados', (tester) async {
    const building = Building(id: 'b', campusId: 'c', name: 'Biblioteca', floorsCount: 1, latitude: 1, longitude: 2);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CampusSearchSheet(buildings: const [building], structures: const [], embedded: true, searchRooms: (_) async => [], loadCategories: () async => []))));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Biblioteca');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.text('Edificios'));
    await tester.pump();
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'Biblioteca'), findsOneWidget);
    await tester.tap(find.text('Edificios'));
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'Biblioteca'), findsNothing);
  });
  testWidgets('busca servicios y mantiene textos independientes', (
    tester,
  ) async {
    const building = Building(
      id: 'b',
      campusId: 'c',
      name: 'Biblioteca',
      floorsCount: 1,
      latitude: 1,
      longitude: 2,
    );
    const structure = StructureLocationDto(
      id: 's',
      name: 'Servicio de prueba',
      location: CampusCoordinateDto(latitude: 1, longitude: 2),
      campusId: 'c',
      categoryId: 'cat',
      categoryName: 'Servicio',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: CampusSearchSheet(
                  buildings: const [building],
                  structures: const [structure],
                  embedded: true,
                  searchRooms: (_) async => [],
                  loadCategories: () async => [],
                ),
              ),
              Expanded(
                child: CampusSearchSheet(
                  buildings: const [building],
                  structures: const [structure],
                  embedded: true,
                  searchRooms: (_) async => [],
                  loadCategories: () async => [],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'Servicio');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('Servicio de prueba'), findsOneWidget);
    final second = tester.widget<TextField>(find.byType(TextField).last);
    expect(second.controller!.text, isEmpty);
  });
  testWidgets('actualiza los resultados al cambiar la búsqueda', (
    tester,
  ) async {
    const building = Building(
      id: 'b',
      campusId: 'c',
      name: 'Biblioteca',
      floorsCount: 1,
      latitude: 1,
      longitude: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusSearchSheet(
            buildings: const [building],
            structures: const [],
            embedded: true,
            searchRooms: (_) async => [],
            loadCategories: () async => [],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Biblioteca');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.widgetWithText(ListTile, 'Biblioteca'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('No se encontraron resultados.'), findsOneWidget);
  });
}
