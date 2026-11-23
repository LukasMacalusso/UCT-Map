import '../../application/session/session_controller.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/report_dto.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/reports_repository.dart';

Future<List<Ticket>> loadUserReports(
  ReportsRepository repository,
  SessionController session,
) async {
  await session.ready;
  final token = session.token;
  final userId = session.currentUser?.id;
  if (token == null || userId == null) throw const UnauthorizedException();
  void check() {
    if (session.token != token || session.currentUser?.id != userId) {
      throw const UnauthorizedException('La sesión cambió.');
    }
  }

  final result = <Ticket>[];
  final seen = <String>{};
  var page = 1;
  while (true) {
    check();
    final response = await repository.getReports(
      filter: ReportFilterParams(userRefId: userId, page: page, pageSize: 50),
    );
    check();
    if (response.page != page ||
        response.totalPages < 0 ||
        (response.hasNextPage && response.items.isEmpty)) {
      throw const FormatException('Paginación de reportes inválida.');
    }
    for (final report in response.items) {
      if (report.userRefId != userId ||
          report.id.isEmpty ||
          !seen.add(report.id)) {
        throw const FormatException(
          'Los reportes no corresponden a tu consulta.',
        );
      }
      result.add(report);
    }
    if (!response.hasNextPage) break;
    page++;
  }
  return result;
}
