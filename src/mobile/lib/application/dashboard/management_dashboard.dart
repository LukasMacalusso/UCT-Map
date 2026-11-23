import '../../data/models/report_dto.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/entities/lost_object.dart';
import '../../domain/repositories/lost_objects_repository.dart';
import '../../data/models/lost_object_dto.dart';
import '../../domain/repositories/identity_repository.dart';

class AdminDashboardSummary {
  const AdminDashboardSummary({required this.total, required this.suspended});
  final int total;
  final int suspended;
  int get active => total - suspended;
}

Future<AdminDashboardSummary> loadAdminDashboard(
  IdentityRepository repository,
  void Function() checkSession,
) async {
  checkSession();
  final users = await repository.getUsers();
  checkSession();
  if (users.any((u) => u.id.isEmpty) ||
      users.map((u) => u.id).toSet().length != users.length) {
    throw const FormatException(
      'El listado de usuarios contiene identificadores inválidos.',
    );
  }
  return AdminDashboardSummary(
    total: users.length,
    suspended: users.where((u) => u.isSuspended).length,
  );
}

class ObjectsDashboardSummary {
  const ObjectsDashboardSummary({required this.total, required this.recent});
  final int? total;
  final List<LostObject> recent;
  bool get missingIds => recent.any((item) => item.id.isEmpty);
}

Future<ObjectsDashboardSummary> loadObjectsDashboard(
  LostObjectsRepository repository,
  void Function() checkSession,
) async {
  checkSession();
  final page = await repository.getLostObjects(
    filter: const LostObjectFilterParams(pageSize: 3),
  );
  checkSession();
  if (page.hasTotalCount &&
      (page.totalCount < page.items.length ||
          (page.totalCount > 0 && page.items.isEmpty))) {
    throw const FormatException(
      'El resumen de objetos no corresponde al listado.',
    );
  }
  return ObjectsDashboardSummary(
    total: page.hasTotalCount ? page.totalCount : null,
    recent: page.items.take(3).toList(),
  );
}

class ComplaintsDashboardSummary {
  const ComplaintsDashboardSummary({required this.total, required this.recent});
  final int? total;
  final List<Ticket> recent;
}

Future<ComplaintsDashboardSummary> loadComplaintsDashboard(
  ReportsRepository repository,
  void Function() checkSession,
) async {
  checkSession();
  final page = await repository.getReports(
    filter: const ReportFilterParams(pageSize: 3),
  );
  checkSession();
  if (page.hasTotalCount &&
      (page.totalCount < page.items.length ||
          (page.totalCount > 0 && page.items.isEmpty))) {
    throw const FormatException(
      'El resumen de incidentes no corresponde al listado.',
    );
  }
  return ComplaintsDashboardSummary(
    total: page.hasTotalCount ? page.totalCount : null,
    recent: page.items.take(3).toList(),
  );
}
