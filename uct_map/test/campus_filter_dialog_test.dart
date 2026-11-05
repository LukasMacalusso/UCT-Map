import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/domain/entities/building.dart';
import 'package:uct_map/domain/entities/campus.dart';
import 'package:uct_map/domain/entities/structure.dart';
import 'package:uct_map/domain/repositories/campus_repository.dart';
import 'package:uct_map/presentation/widgets/campus_filter_dialog.dart';

class _CampusFixture implements CampusRepository {
  @override
  Future<List<Campus>> getCampuses() async => [
    const Campus(
      id: 'campus',
      name: 'Campus Demo',
      address: '',
      latitude: 0,
      longitude: 0,
    ),
  ];
  @override
  Future<List<Building>> getBuildings(String campusId) async => [
    const Building(
      id: 'edificio',
      campusId: 'campus',
      name: 'Edificio Demo',
      floorsCount: 1,
      latitude: 0,
      longitude: 0,
    ),
  ];
  @override
  Future<List<Structure>> getStructures(String campusId) async => [
    const Structure(
      id: 'estructura',
      campusId: 'campus',
      categoryId: '',
      name: 'Biblioteca Demo',
      latitude: 0,
      longitude: 0,
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('selección de campus incluye todos sus lugares', (tester) async {
    CampusFilterSelection? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showCampusFilterDialog(
                  context,
                  repository: _CampusFixture(),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campus Demo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(result?.label, 'Campus Demo');
    expect(result?.locationId, isNull);
    expect(result?.locationIds, {'edificio', 'estructura'});
  });
}
