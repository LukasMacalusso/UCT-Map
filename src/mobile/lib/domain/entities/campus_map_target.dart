/// Destino real del mapa. Una sala se localiza en su edificio, no en interiores.
class CampusMapTarget {
  const CampusMapTarget.building(String id, {this.roomId})
    : buildingId = id,
      structureId = null,
      locationId = null;
  const CampusMapTarget.structure(String id)
    : structureId = id,
      buildingId = null,
      roomId = null,
      locationId = null;
  const CampusMapTarget.location(String id)
    : locationId = id,
      structureId = null,
      buildingId = null,
      roomId = null;
  final String? buildingId;
  final String? structureId;
  final String? roomId;
  final String? locationId;
}
