class CampusSearchFilter {
  const CampusSearchFilter({this.buildingId, this.categoryId});
  final String? buildingId;
  final String? categoryId;

  bool matches({String? building, String? category}) =>
      (buildingId == null || buildingId == building) &&
      (categoryId == null || categoryId == category);
}
