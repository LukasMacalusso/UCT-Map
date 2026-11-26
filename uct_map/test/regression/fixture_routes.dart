import 'package:uct_map/core/network/api_endpoints.dart';

abstract final class FixtureRoutes {
  static final identity = _parent(ApiEndpoints.identityLogin);
  static final officeHours =
      '${_parent(ApiEndpoints.scheduleMeetings)}/office-hours';
  static final campusPrefix = '${_parent(ApiEndpoints.campusList)}/';
  static final incidentPrefix = '${_parent(ApiEndpoints.incidentReports)}/';

  static String studentMeetings(String id) =>
      '${_parent(ApiEndpoints.scheduleMeetings)}/students/$id/meetings';

  static String _parent(String path) =>
      path.substring(0, path.lastIndexOf('/'));
}
