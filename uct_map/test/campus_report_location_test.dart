import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/navigation/campus_location.dart';
import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/data/models/campus_location_dto.dart';
import 'package:uct_map/domain/entities/building.dart';
import 'package:uct_map/domain/entities/campus.dart';
import 'package:uct_map/domain/entities/campus_map_target.dart';
import 'package:uct_map/domain/entities/structure.dart';
import 'package:uct_map/domain/repositories/campus_repository.dart';

class _CampusFixture implements CampusRepository {
  _CampusFixture({this.building = false, this.offline = false});
  final bool building;
  final bool offline;
  int buildingLookups = 0;
  static const campus = Campus(id: 'jp2', name: 'Campus San Juan Pablo II', address: '', latitude: -38.7, longitude: -72.6);
  static const coord = CampusCoordinateDto(latitude: -38.7001, longitude: -72.6001);
  @override Future<Structure> getStructureById(String id) async {
    if (offline) throw const NetworkException();
    if (building) throw const NotFoundException();
    return Structure(id: id, campusId: campus.id, categoryId: '', name: 'Biblioteca', latitude: coord.latitude, longitude: coord.longitude);
  }
  @override Future<Building> getBuildingById(String id) async {
    buildingLookups++;
    return Building(id: id, campusId: campus.id, name: 'Edificio', floorsCount: 1, latitude: coord.latitude, longitude: coord.longitude);
  }
  @override Future<Campus> getCampusById(String id) async => campus;
  @override Future<List<StructureLocationDto>> getStructureLocations({String? campusId}) async => [const StructureLocationDto(id: 'destino', name: 'Biblioteca', campusId: 'jp2', categoryId: '', categoryName: '', location: coord)];
  @override Future<List<BuildingLocationDto>> getBuildingLocations({String? campusId}) async => [const BuildingLocationDto(id: 'destino', name: 'Edificio', campusId: 'jp2', floorsCount: 1, schedule: '', services: [], location: coord)];
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('ubicación de reporte resuelve una estructura en Juan Pablo II', () async {
    final result = await resolveCampusLocation(_CampusFixture(), const CampusMapTarget.location('destino'));
    expect(result.structure?.name, 'Biblioteca');
    expect(result.campus.name, 'Campus San Juan Pablo II');
  });
  test('ubicación de reporte resuelve un edificio cuando no es estructura', () async {
    final result = await resolveCampusLocation(_CampusFixture(building: true), const CampusMapTarget.location('destino'));
    expect(result.building?.name, 'Edificio');
    expect(result.building?.latitude, -38.7001);
  });
  test('un error de red no se confunde con un edificio', () async {
    final repo = _CampusFixture(offline: true);
    await expectLater(resolveCampusLocation(repo, const CampusMapTarget.location('destino')), throwsA(isA<NetworkException>()));
    expect(repo.buildingLookups, 0);
  });
}
