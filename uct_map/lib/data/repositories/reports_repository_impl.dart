import '../../domain/entities/ticket.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_ds.dart';
import '../models/report_dto.dart';

/// Implementación del repositorio de Reportes según Clean Architecture.
class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource _remoteDataSource;

  ReportsRepositoryImpl({
    ReportsRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? ReportsRemoteDataSource();

  @override
  Future<CreateReportResponse> createReport(CreateReportDto dto) {
    return _remoteDataSource.createReport(dto);
  }

  @override
  Future<PaginatedReportsResponse> getReports({ReportFilterParams? filter}) {
    return _remoteDataSource.getReports(filter: filter);
  }

  @override
  Future<Ticket> getReportById(String id) {
    return _remoteDataSource.getReportById(id);
  }

  @override
  Future<void> updateReportStatus(
    String id, {
    required TicketStatus status,
    ComplaintStatus? complainStatus,
  }) {
    return _remoteDataSource.updateReportStatus(
      id,
      status: status,
      complainStatus: complainStatus,
    );
  }
}
