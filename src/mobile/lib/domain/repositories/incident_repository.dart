import '../entities/lost_item.dart';
import '../entities/report.dart';

/// Contrato del repositorio para consumir el Incident Service vía API Gateway.
abstract class IncidentRepository {
  Future<List<LostItem>> getLostItems({String? campus, String? category});
  Future<LostItem> createLostItem(LostItem item);
  Future<List<Report>> getReports({String? campus});
  Future<Report> createReport(Report report);
  Future<bool> updateTicketStatus(String ticketId, String status);
}
