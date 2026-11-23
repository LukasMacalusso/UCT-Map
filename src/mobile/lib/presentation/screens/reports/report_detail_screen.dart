import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/report.dart';

// Pantalla de detalle de un reporte: muestra toda la informacion y
// el historial de estados con estilo de lista de tareas (timeline).
class ReportDetailScreen extends StatelessWidget {
  final Report report;
  final Function(int)? onNavigateToTab;

  const ReportDetailScreen({
    super.key,
    required this.report,
    this.onNavigateToTab,
  });

  static const List<ReportStatus> _allStatuses = [
    ReportStatus.reportado,
    ReportStatus.enRevision,
    ReportStatus.enProceso,
    ReportStatus.resuelto,
  ];

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
        return Icons.flag_outlined;
      case ReportStatus.enRevision:
        return Icons.search_outlined;
      case ReportStatus.enProceso:
        return Icons.construction_outlined;
      case ReportStatus.resuelto:
        return Icons.check_circle_outline;
    }
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} - $h:$m';
  }

  void _goToMap(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ubicando "${report.location}" en el mapa...'),
        duration: const Duration(seconds: 2),
      ),
    );
    if (onNavigateToTab != null) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, 0);
      }
      onNavigateToTab!(0);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, 0);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.initial, arguments: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _allStatuses.indexOf(report.currentStatus);
    final Color accentColor = _statusColor(report.currentStatus);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Detalle del Reporte',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Ver ubicación en mapa',
            onPressed: () => _goToMap(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- Header Card ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.uctBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          report.currentStatus.label,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    report.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.uctYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          report.location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.uctYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.campus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: AppColors.uctYellow,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reportado por ${report.reportedBy}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _goToMap(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.uctYellow,
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(
                        Icons.map_outlined,
                        size: 16,
                        color: AppColors.uctYellow,
                      ),
                      label: const Text(
                        'Ver ubicación en el Mapa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ---- Descripcion ----
            const Text(
              'Descripcion',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Text(
                report.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.subtitle,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Foto del reporte ----
            const Text(
              'Foto del reporte',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: report.imageUrl != null
                    ? Image.network(
                        report.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            const _ImagePlaceholder(hasError: true),
                      )
                    : const _ImagePlaceholder(hasError: false),
              ),
            ),
            const SizedBox(height: 24),

            // ---- Timeline de estados ----
            const Text(
              'Historial de estados',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),

            ...List.generate(_allStatuses.length, (i) {
              final status = _allStatuses[i];
              final isDone = i < currentIndex;
              final isCurrent = i == currentIndex;
              final isPending = i > currentIndex;
              final isLast = i == _allStatuses.length - 1;

              // Buscar el evento del historial para este estado
              final ReportStatusEvent? event = report.statusHistory
                  .cast<ReportStatusEvent?>()
                  .firstWhere((e) => e!.status == status, orElse: () => null);

              final Color dotColor = isDone
                  ? Colors.green
                  : isCurrent
                  ? accentColor
                  : Colors.grey.shade300;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Linea vertical + circulo
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? Colors.green.withValues(alpha: 0.12)
                              : isCurrent
                              ? accentColor.withValues(alpha: 0.12)
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: dotColor,
                            width: isCurrent ? 2.5 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.green,
                                )
                              : Icon(
                                  _statusIcon(status),
                                  size: 16,
                                  color: isCurrent
                                      ? accentColor
                                      : Colors.grey.shade400,
                                ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 48,
                          color: isDone
                              ? Colors.green.withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Contenido del estado
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isPending
                                  ? Colors.grey.shade400
                                  : AppColors.ink,
                            ),
                          ),
                          if (event != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(event.at),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.subtitle,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Por: ${event.by}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.hint,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 2),
                            Text(
                              'Pendiente',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: placeholder para la foto del reporte
// ---------------------------------------------------------------------------
class _ImagePlaceholder extends StatelessWidget {
  final bool hasError;
  const _ImagePlaceholder({required this.hasError});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError
                ? Icons.broken_image_outlined
                : Icons.add_photo_alternate_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            hasError ? 'No se pudo cargar la imagen' : 'Sin foto adjunta',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!hasError) ...[
            const SizedBox(height: 6),
            Text(
              'La foto se agregara al crear o editar el reporte',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}
