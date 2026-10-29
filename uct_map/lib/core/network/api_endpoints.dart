/// Rutas de los microservicios expuestos a través del API Gateway (ms.svg).
class ApiEndpoints {
  const ApiEndpoints._();

  // -------------------------------------------------------------
  // Identity Service (SSO, Roles, JWT) -> /api/identity
  // -------------------------------------------------------------
  static const String identityLogin = '/api/identity/login';
  static const String identityMe = '/api/identity/me';

  // -------------------------------------------------------------
  // Campus Service -> /api/campus
  // -------------------------------------------------------------

  // Campus
  static const String campusList = '/api/campus/campuses';

  static String campusDetail(String campusId) =>
      '/api/campus/campuses/$campusId';

  // Edificios
  static const String campusBuildingsList = '/api/campus/buildings';

  static String campusBuildings(String campusId) =>
      '/api/campus/buildings?campusId=$campusId';

  static String buildingDetail(String buildingId) =>
      '/api/campus/buildings/$buildingId';

  static String buildingRooms(String buildingId) =>
      '/api/campus/buildings/$buildingId/rooms';

  static String buildingLocations(String campusId) =>
      '/api/campus/buildings/locations?campusId=$campusId';

  static const String campusBuildingLocationsPath =
      '/api/campus/buildings/locations';
  // Salas
  static const String campusRooms = '/api/campus/rooms';

  static String roomDetail(String roomId) => '/api/campus/rooms/$roomId';

  static String roomSearch(String term) =>
      '/api/campus/rooms/search?term=${Uri.encodeQueryComponent(term)}';

  static const String campusRoomSearchPath = '/api/campus/rooms/search';
  // Estructuras
  static const String campusStructuresList = '/api/campus/structures';

  static String campusStructures(String campusId) =>
      '/api/campus/structures?campusId=$campusId';

  static String structureDetail(String structureId) =>
      '/api/campus/structures/$structureId';

  static String structureLocations(String campusId) =>
      '/api/campus/structures/locations?campusId=$campusId';

  static const String campusStructureLocationsPath =
      '/api/campus/structures/locations';

  // Categorías
  static const String campusCategories = '/api/campus/categories';

  static String categoryDetail(String categoryId) =>
      '/api/campus/categories/$categoryId';

  // -------------------------------------------------------------
  // Schedule Service (Directorio, Citas, Horarios) -> /api/schedule
  // -------------------------------------------------------------
  static const String scheduleProfessors = '/api/schedule/professors';
  static String professorOfficeHours(String teacherId) =>
      '/api/schedule/professors/$teacherId/office-hours';
  static const String scheduleMeetings = '/api/schedule/meetings';
  static String meetingStatus(String meetingId) =>
      '/api/schedule/meetings/$meetingId/status';

  // -------------------------------------------------------------
  // Incident Service (Quejas, Objetos Perdidos) -> /api/incident
  // -------------------------------------------------------------
  static const String incidentLostObjects = '/api/incident/lost-objects';
  static String incidentLostObjectStatus(String id) =>
      '/api/incident/lost-objects/$id/lost/status';

  static const String incidentLostItems = '/api/incident/lost-items';
  static String incidentLostItemDetail(String ticketId) =>
      '/api/incident/lost-items/$ticketId';
  static const String incidentReports = '/api/incident/reports';
  static String incidentReportDetail(String reportId) =>
      '/api/incident/reports/$reportId';
  static String incidentReportStatus(String id) =>
      '/api/incident/reports/$id/report/status';
  static String incidentTicketStatus(String ticketId) =>
      '/api/incident/tickets/$ticketId/status';
}
