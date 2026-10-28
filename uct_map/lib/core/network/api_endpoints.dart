/// Rutas de los microservicios expuestos a través del API Gateway (ms.svg).
class ApiEndpoints {
  const ApiEndpoints._();

  // -------------------------------------------------------------
  // Identity Service (SSO, Roles, JWT) -> /api/identity
  // -------------------------------------------------------------
  static const String identityLogin = '/api/identity/login';
  static const String identityMe = '/api/identity/me';

  // -------------------------------------------------------------
  // Campus Service (Mapas, Edificios, Salas) -> /api/campus
  // -------------------------------------------------------------
  static const String campusList = '/api/campus';
  static String campusBuildings(String campusId) =>
      '/api/campus/$campusId/buildings';
  static String buildingRooms(String buildingId) =>
      '/api/campus/buildings/$buildingId/rooms';
  static String campusStructures(String campusId) =>
      '/api/campus/$campusId/structures';
  static const String campusCategories = '/api/campus/categories';
  static const String campusRoute = '/api/campus/route';

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
