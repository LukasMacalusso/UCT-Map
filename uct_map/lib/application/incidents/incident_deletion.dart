import '../session/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/report_dto.dart';
import '../../domain/entities/app_permission.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/repositories/lost_objects_repository.dart';

class IncidentDeletion {
  IncidentDeletion({
    required this.session,
    required this.reports,
    required this.objects,
  }) : _token = session.token;
  final SessionController session;
  final ReportsRepository reports;
  final LostObjectsRepository objects;
  final String? _token;
  void _check(AppPermission permission) {
    if (_token == null ||
        session.token != _token ||
        !session.isAuthenticated ||
        !permission.allows(session.currentUser?.role)) {
      throw const UnauthorizedException('La sesión o los permisos cambiaron.');
    }
  }

  Future<void> deleteReport(String id) async {
    _check(AppPermission.manageReports);
    final ticket = await reports.getReportById(id);
    _check(AppPermission.manageReports);
    if (ticket.id != id || ticket.complaintDetails == null) {
      throw StateError('El registro no es una incidencia válida.');
    }
    if (ticket.lostObjectId?.isNotEmpty == true) {
      throw StateError(
        'Esta incidencia tiene un objeto vinculado. Su borrado requiere soporte del servicio para conservar la relación.',
      );
    }
    await reports.deleteReport(id);
    _check(AppPermission.manageReports);
  }

  Future<void> deleteObject(String id) async {
    _check(AppPermission.manageObjects);
    final item = await objects.getLostObjectById(id);
    _check(AppPermission.manageObjects);
    if (item.id != id)
      throw StateError('El objeto no corresponde a la consulta.');
    final links = await reports.getReports(
      filter: ReportFilterParams(lostObjectId: id, pageSize: 1),
    );
    _check(AppPermission.manageObjects);
    if (links.page != 1 ||
        links.totalCount < 0 ||
        (links.totalCount > 0 && links.items.isEmpty)) {
      throw const FormatException('No se pudieron comprobar los vínculos.');
    }
    if (links.items.isNotEmpty || links.totalCount > 0 || links.hasNextPage) {
      throw StateError(
        'Este objeto está vinculado a reportes. El servicio debe resolver esos vínculos antes de permitir su borrado.',
      );
    }
    // shortcut: la comprobación no es atómica; Incident debe proteger también nuevas referencias concurrentes.
    await objects.deleteLostObject(id);
    _check(AppPermission.manageObjects);
  }
}
