import '../../domain/entities/ticket.dart';
import '../session/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/lost_object.dart';
import '../../domain/repositories/lost_objects_repository.dart';
import '../../domain/repositories/reports_repository.dart';
import 'user_reports.dart';

Future<({List<LostObject> items, int unavailable})> loadUserObjects(
  ReportsRepository reports,
  LostObjectsRepository objects,
  SessionController session, {
  List<Ticket>? loadedReports,
}) async {
  await session.ready;
  final token = session.token;
  final userId = session.currentUser?.id;
  if (token == null || userId == null) throw const UnauthorizedException();
  void check() {
    if (session.token != token || session.currentUser?.id != userId)
      throw const UnauthorizedException('La sesión cambió.');
  }

  final tickets = loadedReports ?? await loadUserReports(reports, session);
  if (tickets.any((r) => r.userRefId != userId))
    throw const FormatException("Los reportes no corresponden a tu cuenta.");
  check();
  final ids = tickets
      .map((r) => r.lostObjectId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();
  final result = <LostObject>[];
  var unavailable = 0;
  for (final id in ids) {
    check();
    try {
      final object = await objects.getLostObjectById(id);
      check();
      if (object.id != id)
        throw const FormatException('El objeto no corresponde a tu consulta.');
      result.add(object);
    } on ApiException catch (error) {
      check();
      if (error.statusCode != 404) rethrow;
      unavailable++;
    }
  }
  return (items: result, unavailable: unavailable);
}
