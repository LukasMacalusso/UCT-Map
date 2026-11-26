import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/directory/filter_professors.dart';
import 'package:uct_map/data/models/campus_location_dto.dart';
import 'package:uct_map/domain/entities/building.dart';
import 'package:uct_map/domain/entities/category.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/professor.dart';
import 'package:uct_map/presentation/screens/map/widgets/campus_search_sheet.dart';

void main() {
  group('Búsqueda de campus', () {
    for (final embedded in [true, false]) {
      testWidgets(
        'controles existentes filtran sin chips redundantes: embedded=$embedded',
        (tester) async {
          var categoriesCalls = 0;
          var selected = false;
          const building = Building(
            id: 'b',
            campusId: 'c',
            name: 'Edificio de consulta',
            floorsCount: 1,
            latitude: 1,
            longitude: 1,
          );
          const structure = StructureLocationDto(
            id: 's',
            name: 'Punto de consulta',
            campusId: 'c',
            categoryId: 'category',
            categoryName: 'Consultas Fork',
            location: CampusCoordinateDto(latitude: 1, longitude: 1),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: CampusSearchSheet(
                  embedded: embedded,
                  buildings: const [building],
                  structures: const [structure],
                  searchRooms: (_) async => [],
                  loadCategories: () async {
                    categoriesCalls++;
                    return [
                      const Category(
                        id: 'category',
                        name: 'Consultas Fork',
                        icon: 'school',
                        description: '',
                      ),
                    ];
                  },
                  onSelected: (_) => selected = true,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(FilterChip), findsNothing);
          expect(categoriesCalls, 0);
          await tester.enterText(find.byType(TextField), 'consulta');
          await tester.pump(const Duration(milliseconds: 350));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Edificios'));
          await tester.pumpAndSettle();
          if (embedded) {
            await tester.scrollUntilVisible(
              find.widgetWithText(ListTile, building.name),
              120,
              scrollable: find.byType(Scrollable).first,
            );
          }
          expect(find.widgetWithText(ListTile, building.name), findsOneWidget);
          expect(find.widgetWithText(ListTile, structure.name), findsNothing);
          await tester.ensureVisible(
            find.widgetWithText(ListTile, building.name),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ListTile, building.name));
          expect(selected, isTrue);
          await tester.ensureVisible(find.text('Servicios'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Servicios'));
          await tester.pumpAndSettle();
          expect(find.widgetWithText(ListTile, building.name), findsNothing);
          expect(find.widgetWithText(ListTile, structure.name), findsOneWidget);
          expect(find.byType(FilterChip), findsNothing);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  });

  group('Filtros de directorio', () {
    const hours = [
      OfficeHour(
        id: 'm',
        teacherRefId: 't',
        structureRefId: 'a',
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '10:00',
      ),
      OfficeHour(
        id: 't',
        teacherRefId: 't',
        structureRefId: 'b',
        dayOfWeek: 2,
        startTime: '09:00',
        endTime: '10:00',
      ),
    ];
    const teacher = Professor(
      id: 't',
      name: 'Docente',
      department: '',
      office: '',
      email: 'docente@uct.cl',
      officeHours: hours,
    );
    const without = Professor(
      id: 'w',
      name: 'Sin horario',
      department: '',
      office: '',
      email: 'sin@uct.cl',
    );
    test('día y campus deben coincidir en el mismo bloque de atención', () {
      expect(
        filterProfessors(
          [teacher],
          campusId: 'campus-a',
          weekday: 2,
          campusByLocation: {'a': 'campus-a', 'b': 'campus-b'},
        ),
        isEmpty,
      );
      expect(
        filterProfessors(
          [teacher],
          campusId: 'campus-a',
          weekday: 1,
          campusByLocation: {'a': 'campus-a', 'b': 'campus-b'},
        ).single.id,
        't',
      );
    });
    test('con/sin horario y búsqueda por correo se combinan sin perder docentes sin bloques', () {
      expect(
        filterProfessors([teacher, without], hasOfficeHours: false).single.id,
        'w',
      );
      expect(
        filterProfessors(
          [teacher, without],
          query: 'DOCENTE@',
          hasOfficeHours: true,
        ).single.id,
        't',
      );
      expect(
        filterProfessors(
          [teacher, without],
          locationId: 'a',
          hasOfficeHours: false,
        ),
        isEmpty,
      );
    });
  });
}
