import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/problem_details.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/repositories/reports_repository.dart';
import 'widgets/ticket_status_badge.dart';

/// Pantalla de Detalle de un Reporte / Ticket que consume GET /api/incident/reports/{id}.
class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final ReportsRepository repository;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    required this.repository,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Ticket? _ticket;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final t = await widget.repository.getReportById(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = t;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is ProblemDetailsException) {
        message = e.problemDetails.userMessage;
      } else if (e is ApiException) {
        message = e.message;
      } else {
        message = 'No se pudo cargar el detalle del reporte.';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus() async {
    final ticket = _ticket;
    if (ticket == null) return;

    TicketStatus selectedTicketStatus = ticket.ticketType;
    ComplaintStatus? selectedComplaintStatus = ticket.complaintDetails?.status;

    final updated = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Actualizar Estado',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Estado del Ticket:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: TicketStatus.values.map((s) {
                        final isSel = selectedTicketStatus == s;
                        return ChoiceChip(
                          avatar: isSel ? const Icon(Icons.check, size: 14) : null,
                          label: Text(s.label),
                          selected: isSel,
                          onSelected: (_) => setModalState(() => selectedTicketStatus = s),
                        );
                      }).toList(),
                    ),
                    if (ticket.complaintDetails != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Estado de Queja / Reclamo:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ComplaintStatus.values.map((cs) {
                          final isSel = selectedComplaintStatus == cs;
                          return ChoiceChip(
                            avatar: isSel ? const Icon(Icons.check, size: 14) : null,
                            label: Text(cs.label),
                            selected: isSel,
                            onSelected: (_) => setModalState(() => selectedComplaintStatus = cs),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.uctBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx, true);
                          try {
                            await widget.repository.updateReportStatus(
                              ticket.id,
                              status: selectedTicketStatus,
                              complainStatus: selectedComplaintStatus,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Estado actualizado con éxito'),
                                  backgroundColor: Color(0xFF047857),
                                ),
                              );
                              _fetchDetail();
                            }
                          } catch (err) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(err.toString()),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Guardar Cambios'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (updated == true) {
      _fetchDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle del Reporte',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDetail,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _ticket != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _changeStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.uctBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text(
                    'Cambiar Estado del Reporte',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.uctBlue));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _fetchDetail,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final ticket = _ticket!;
    final complaint = ticket.complaintDetails;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estados (Badges)
          Row(
            children: [
              TicketStatusBadge(status: ticket.ticketType),
              const SizedBox(width: 8),
              if (complaint != null)
                ComplaintStatusBadge(status: complaint.status),
            ],
          ),
          const SizedBox(height: 18),

          // Título de la queja
          Text(
            complaint?.title.isNotEmpty == true
                ? complaint!.title
                : 'Reporte de Incidencia',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),

          // Descripción de la queja
          if (complaint?.description.isNotEmpty == true) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Text(
                complaint!.description,
                style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.ink),
              ),
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            'Información Técnica',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 10),

          _buildInfoRow('ID del Reporte:', ticket.id, isMonospace: true),
          _buildInfoRow(
            'Estructura (structureRefId):',
            ticket.structureRefId,
            isMonospace: true,
          ),
          if (ticket.userRefId != null)
            _buildInfoRow(
              'Autor (userRefId):',
              ticket.userRefId!,
              isMonospace: true,
            ),
          _buildInfoRow(
            'Fecha Reportada:',
            '${ticket.reportedAt.day}/${ticket.reportedAt.month}/${ticket.reportedAt.year} ${ticket.reportedAt.hour}:${ticket.reportedAt.minute}',
          ),
          _buildInfoRow('Activo:', ticket.isActive ? 'Sí (Activo)' : 'No (Inactivo)'),

          if (ticket.lostObjectId?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              'Objeto Perdido Asociado:',
              ticket.lostObjectId!,
              isMonospace: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.subtitle, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: TextStyle(
              fontSize: 13,
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
