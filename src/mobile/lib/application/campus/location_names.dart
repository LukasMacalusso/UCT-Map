import '../../domain/repositories/campus_repository.dart';

Future<Map<String, String>> loadLocationNames(
  CampusRepository repository,
) async {
  final campuses = await repository.getCampuses();
  final names = {for (final campus in campuses) campus.id: campus.name};
  final buildings = await repository.getBuildingLocations();
  final structures = await repository.getStructureLocations();
  String label(String name, String campusId) =>
      names.containsKey(campusId) ? '$name · ${names[campusId]}' : name;
  return {
    for (final building in buildings)
      building.id: label(building.name, building.campusId),
    for (final structure in structures)
      structure.id: label(structure.name, structure.campusId),
  };
}
