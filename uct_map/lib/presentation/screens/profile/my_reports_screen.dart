import 'package:flutter/material.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/report.dart';
import '../login/session_required_view.dart';
import '../reports/report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const MyReportsScreen({super.key, this.onNavigateToTab});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _selectedFilter = 'Todos';

  // Reportes asociados al perfil del estudiante
  final List<Report> _userReports = [
    Report(
      id: 'usr-1',
      title: 'Proyector con falla técnica en Sala C-201',
      description:
          'El proyector de la Sala C-201 no enciende. Se probó con distintos cables HDMI y el problema persiste. Afecta el desarrollo de las clases.',
      location: 'Sala C-201, Edificio C',
      campus: 'Campus San Francisco',
      reportedBy: 'Patricio Benavides (Estudiante)',
      reportedAt: DateTime(2026, 9, 14, 10, 15),
      currentStatus: ReportStatus.enProceso,
      statusHistory: [
        ReportStatusEvent(
          status: ReportStatus.reportado,
          at: DateTime(2026, 9, 14, 10, 15),
          by: 'Patricio Benavides',
        ),
        ReportStatusEvent(
          status: ReportStatus.enRevision,
          at: DateTime(2026, 9, 14, 11, 30),
          by: 'Soporte TI Campus',
        ),
        ReportStatusEvent(
          status: ReportStatus.enProceso,
          at: DateTime(2026, 9, 15, 9, 00),
          by: 'Técnico de Infraestructura',
        ),
      ],
    ),
    Report(
      id: 'usr-2',
      title: 'Dispensador de jabón dañado en baño piso 1',
      description:
          'El dispensador de jabón del baño de varones primer piso está roto y gotea en el suelo, provocando riesgo de caída.',
      location: 'Baño 1er Piso, Edificio A',
      campus: 'Campus San Juan Pablo II',
      reportedBy: 'Patricio Benavides (Estudiante)',
      reportedAt: DateTime(2026, 9, 12, 14, 20),
      currentStatus: ReportStatus.resuelto,
      statusHistory: [
        ReportStatusEvent(
          status: ReportStatus.reportado,
          at: DateTime(2026, 9, 12, 14, 20),
          by: 'Patricio Benavides',
        ),
        ReportStatusEvent(
          status: ReportStatus.enRevision,
          at: DateTime(2026, 9, 12, 16, 00),
          by: 'Mantención Campus',
        ),
        ReportStatusEvent(
          status: ReportStatus.resuelto,
          at: DateTime(2026, 9, 13, 11, 45),
          by: 'Equipo de Servicios Generales',
        ),
      ],
    ),
    Report(
      id: 'usr-3',
      title: 'Enchufe sin energía en mesón de estudio',
      description:
          'Los enchufes del mesón central de la biblioteca no entregan energía para conectar notebooks de estudio.',
      location: 'Biblioteca Central, 2do Piso',
      campus: 'Campus San Francisco',
      reportedBy: 'Patricio Benavides (Estudiante)',
      reportedAt: DateTime(2026, 9, 16, 8, 45),
      currentStatus: ReportStatus.enRevision,
      statusHistory: [
        ReportStatusEvent(
          status: ReportStatus.reportado,
          at: DateTime(2026, 9, 16, 8, 45),
          by: 'Patricio Benavides',
        ),
        ReportStatusEvent(
          status: ReportStatus.enRevision,
          at: DateTime(2026, 9, 16, 9, 20),
          by: 'Administración Biblioteca',
        ),
      ],
    ),
  ];

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.reportado:
        return const Color(0xFF0284C7);
      case ReportStatus.enRevision:
        return const Color(0xFFEA580C);
      case ReportStatus.enProceso:
        return const Color(0xFF9333EA);
      case ReportStatus.resuelto:
        return const Color(0xFF16A34A);
    }
  }

  IconData _statusIcon(ReportStatus s) {
    switch (s) {
      case ReportStatus.reportado:
        return Icons.flag_rounded;
      case ReportStatus.enRevision:
        return Icons.search_rounded;
      case ReportStatus.enProceso:
        return Icons.construction_rounded;
      case ReportStatus.resuelto:
        return Icons.check_circle_rounded;
    }
  }

  List<Report> get _filteredReports {
    if (_selectedFilter == 'Todos') return _userReports;
    return _userReports.where((r) {
      switch (_selectedFilter) {
        case 'En Revisión':
          return r.currentStatus == ReportStatus.enRevision;
        case 'En Proceso':
          return r.currentStatus == ReportStatus.enProceso;
        case 'Resuelto':
          return r.currentStatus == ReportStatus.resuelto;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reports = _filteredReports;
    final total = _userReports.length;
    final enProceso = _userReports
        .where((r) =>
            r.currentStatus == ReportStatus.enProceso ||
            r.currentStatus == ReportStatus.enRevision)
        .length;
    final resueltos =
        _userReports.where((r) => r.currentStatus == ReportStatus.resuelto).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Reportes de Incidencias',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Resumen superior en métricas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.uctBlue.withValues(alpha: 0.05),
              border: const Border(
                bottom: BorderSide(color: AppColors.fieldBorder),
              ),
            ),
            child: Row(
              children: [
                _buildStatBadge('Total', total.toString(), AppColors.uctBlue),
                const SizedBox(width: 10),
                _buildStatBadge('En trámite', enProceso.toString(), Colors.orange.shade800),
                const SizedBox(width: 10),
                _buildStatBadge('Resueltos', resueltos.toString(), Colors.green.shade700),
              ],
            ),
          ),

          // Chips de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _filterChip('Todos'),
                const SizedBox(width: 8),
                _filterChip('En Revisión'),
                const SizedBox(width: 8),
                _filterChip('En Proceso'),
                const SizedBox(width: 8),
                _filterChip('Resuelto'),
              ],
            ),
          ),

          // Listado de reportes
          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No hay reportes en este estado',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.subtitle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tus incidencias reportadas aparecerán detalladas aquí con su avance en tiempo real.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.hint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: reports.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildReportCard(report);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.onNavigateToTab != null) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, 3);
                }
                widget.onNavigateToTab!(3); // Navega a la pestaña de reportes
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context, 3);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.initial,
                  arguments: 3,
                );
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Generar Nuevo Reporte de Incidencia'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.uctBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: selected,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? Colors.white : AppColors.ink,
      ),
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.uctBlue,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? AppColors.uctBlue : AppColors.fieldBorder,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
    );
  }

  Widget _buildReportCard(Report report) {
    final statusColor = _statusColor(report.currentStatus);
    final statusIcon = _statusIcon(report.currentStatus);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionRequiredView(
              builder: (_) => ReportDetailScreen(
                report: report,
                onNavigateToTab: widget.onNavigateToTab,
              ),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.fieldBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 13, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          report.currentStatus.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitle,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.fieldBorder),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppColors.subtitle),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${report.location} • ${report.campus}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subtitle,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.hint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
