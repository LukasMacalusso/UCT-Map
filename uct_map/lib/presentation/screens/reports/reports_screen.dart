import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/incident_remote_ds.dart';
import '../../../domain/entities/report.dart';
import '../../../domain/repositories/incident_repository.dart';
import '../login/session_required_view.dart';
import 'report_detail_screen.dart';

// Pantalla de Reportes de Incidencias con filtros, mapa de calor y tarjetas (ms.svg - Incident Service).
class ReportsScreen extends StatefulWidget {
  final bool showAppBar;
  final Function(int)? onNavigateToTab;
  final IncidentRepository? incidentRepository;

  const ReportsScreen({
    super.key,
    this.showAppBar = false,
    this.onNavigateToTab,
    this.incidentRepository,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final IncidentRepository _repository;
  List<Report> _reports = [];
  bool _loading = true;

  // Filtros
  String _selectedCampus = 'Todos';
  bool _newerFirst = true;
  bool _heatmapEnabled = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.incidentRepository ?? IncidentRemoteDataSource();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      final list = await _repository.getReports(campus: _selectedCampus);
      if (mounted) {
        setState(() {
          _reports = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(ReportStatus s) {
    switch (s) {
      case ReportStatus.reportado:
        return Colors.blue;
      case ReportStatus.enRevision:
        return Colors.orange;
      case ReportStatus.enProceso:
        return Colors.purple;
      case ReportStatus.resuelto:
        return Colors.green;
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return 'hace ${diff.inDays} ${diff.inDays == 1 ? 'dia' : 'dias'}';
    } else if (diff.inHours >= 1) {
      return 'hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
    } else {
      return 'hace ${diff.inMinutes} min';
    }
  }

  List<Report> get _filteredReports {
    List<Report> result = _reports.isNotEmpty ? List.from(_reports) : List.from(mockReports);
    if (_selectedCampus != 'Todos') {
      result = result.where((r) => r.campus == _selectedCampus).toList();
    }
    result.sort((a, b) => _newerFirst
        ? b.reportedAt.compareTo(a.reportedAt)
        : a.reportedAt.compareTo(b.reportedAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final reports = _filteredReports;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.uctBlue,
              foregroundColor: Colors.white,
              title: const Text(
                'Reportes de Incidencias',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          // ===== Barra de filtros =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                // Fila 1: Campus selector + Ordenar
                Row(
                  children: [
                    // Campus dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.fieldBorder),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCampus,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.subtitle),
                            style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCampus = val);
                              }
                            },
                            items: campusList
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.account_balance_outlined,
                                              size: 15,
                                              color: AppColors.subtitle),
                                          const SizedBox(width: 6),
                                          Text(c),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Ordenar button
                    GestureDetector(
                      onTap: () =>
                          setState(() => _newerFirst = !_newerFirst),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.fieldBorder),
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.uctBlue.withValues(alpha: 0.06),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _newerFirst
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 15,
                              color: AppColors.uctBlue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _newerFirst ? 'Reciente' : 'Antiguo',
                              style: const TextStyle(
                                  color: AppColors.uctBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Fila 2: Switch mapa de calor
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _heatmapEnabled
                        ? Colors.deepOrange.withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    border: Border.all(
                      color: _heatmapEnabled
                          ? Colors.deepOrange.withValues(alpha: 0.4)
                          : AppColors.fieldBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.whatshot_rounded,
                        color: _heatmapEnabled
                            ? Colors.deepOrange
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mapa de calor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _heatmapEnabled
                              ? Colors.deepOrange
                              : AppColors.subtitle,
                        ),
                      ),
                      const Spacer(),
                      Switch.adaptive(
                        value: _heatmapEnabled,
                        activeThumbColor: Colors.deepOrange,
                        activeTrackColor: Colors.deepOrange.withValues(alpha: 0.4),
                        onChanged: (val) {
                          setState(() => _heatmapEnabled = val);
                          if (val) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Mapa de calor activado (proximamente disponible)'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.fieldBorder),
          // ===== Lista de reportes =====
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : reports.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay reportes para este campus.',
                          style:
                              TextStyle(color: AppColors.subtitle, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: reports.length,
                    itemBuilder: (ctx, i) =>
                        _ReportCard(
                          report: reports[i],
                          statusColor: _statusColor(reports[i].currentStatus),
                          statusIcon: _statusIcon(reports[i].currentStatus),
                          timeAgo: _timeAgo(reports[i].reportedAt),
                          onNavigateToTab: widget.onNavigateToTab,
                        ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'reports_fab',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulario para nuevo reporte')),
          );
        },
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Nuevo Reporte',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de reporte
// ---------------------------------------------------------------------------
class _ReportCard extends StatelessWidget {
  final Report report;
  final Color statusColor;
  final IconData statusIcon;
  final String timeAgo;
  final Function(int)? onNavigateToTab;

  const _ReportCard({
    required this.report,
    required this.statusColor,
    required this.statusIcon,
    required this.timeAgo,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: ubicacion + estado
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ubicacion
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 13, color: AppColors.subtitle),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          report.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.subtitle,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Estado chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        report.currentStatus.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Titulo
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            // Fila: descripcion breve + thumbnail imagen
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Descripcion
                Expanded(
                  child: Text(
                    report.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.subtitle,
                        height: 1.4),
                  ),
                ),
                const SizedBox(width: 10),
                // Thumbnail imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade100,
                    child: report.imageUrl != null
                        ? Image.network(
                            report.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => const _CardImagePlaceholder(),
                          )
                        : const _CardImagePlaceholder(),
                  ),
                ),
              ],
            ),

            // Fila inferior: reportado por + tiempo + boton
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 13, color: AppColors.hint),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    '${report.reportedBy} · $timeAgo',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.hint),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Boton ver detalle
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionRequiredView(
                          builder: (_) => ReportDetailScreen(
                            report: report,
                            onNavigateToTab: onNavigateToTab,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.uctBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Ver detalle',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: thumbnail placeholder en la tarjeta de la lista
// ---------------------------------------------------------------------------
class _CardImagePlaceholder extends StatelessWidget {
  const _CardImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Icon(
          Icons.photo_camera_outlined,
          size: 26,
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}
