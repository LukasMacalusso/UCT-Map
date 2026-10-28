import '../../data/models/report_dto.dart';
import '../entities/ticket.dart';

/// Contrato del repositorio de Reportes / Tickets (Incident Service / Reports).
abstract class ReportsRepository {
  /// Registra un nuevo reporte/ticket (POST /api/incident/reports).
  ///
  /// El usuario autor se asigna automáticamente a partir del JWT Bearer en el backend.
  Future<CreateReportResponse> createReport(CreateReportDto dto);

  /// Consulta el listado paginado de reportes con soporte de filtros.
  Future<PaginatedReportsResponse> getReports({ReportFilterParams? filter});

  /// Obtiene los detalles de un ticket individual por su ID (GET /api/incident/reports/{id}).
  Future<Ticket> getReportById(String id);

  /// Actualiza el estado del reporte y opcionalmente el estado de la queja
  /// (PATCH /api/incident/reports/{id}/report/status).
  Future<void> updateReportStatus(
    String id, {
    required TicketStatus status,
    ComplaintStatus? complainStatus,
  });
}
