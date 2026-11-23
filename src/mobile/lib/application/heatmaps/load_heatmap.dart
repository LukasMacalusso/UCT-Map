import '../../data/models/report_dto.dart';
import '../../data/models/lost_object_dto.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/repositories/lost_objects_repository.dart';

Future<Map<String, int>> loadHeatmapCounts({
  required bool objectsMode,
  required ReportsRepository reports,
  required LostObjectsRepository objects,
  required void Function() checkSession,
}) async {
  final counts = <String, int>{};
  final seen = <String>{};
  var page = 1;
  while (true) {
    checkSession();
    if (objectsMode) {
      final batch = await objects.getLostObjects(
        filter: LostObjectFilterParams(page: page),
      );
      checkSession();
      if (batch.page != page || (batch.hasNextPage && batch.items.isEmpty))
        throw const FormatException('Paginación de objetos inválida.');
      for (final item in batch.items) {
        if (item.id.isEmpty || !seen.add(item.id))
          throw const FormatException('Página de objetos repetida o inválida.');
        if (item.structureId.isNotEmpty)
          counts.update(item.structureId, (n) => n + 1, ifAbsent: () => 1);
      }
      if (!batch.hasNextPage) break;
    } else {
      final batch = await reports.getReports(
        filter: ReportFilterParams(page: page),
      );
      checkSession();
      if (batch.page != page || (batch.hasNextPage && batch.items.isEmpty))
        throw const FormatException('Paginación de incidencias inválida.');
      for (final item in batch.items) {
        if (item.id.isEmpty || !seen.add(item.id))
          throw const FormatException(
            'Página de incidencias repetida o inválida.',
          );
        if (item.complaintDetails != null && item.structureRefId.isNotEmpty)
          counts.update(item.structureRefId, (n) => n + 1, ifAbsent: () => 1);
      }
      if (!batch.hasNextPage) break;
    }
    page++;
  }
  return counts;
}
