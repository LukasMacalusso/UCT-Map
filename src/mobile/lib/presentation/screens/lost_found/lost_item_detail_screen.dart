import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/lost_item.dart';

// Pantalla de detalle de un objeto perdido: header, foto, descripcion,
// contacto y timeline de estados similar al de reportes.
class LostItemDetailScreen extends StatelessWidget {
  final LostItem item;
  final Function(int)? onNavigateToTab;

  const LostItemDetailScreen({
    super.key,
    required this.item,
    this.onNavigateToTab,
  });

  static const List<LostItemStatus> _allStatuses = [
    LostItemStatus.publicado,
    LostItemStatus.enCustodia,
    LostItemStatus.entregado,
    LostItemStatus.cerrado,
  ];

  Color _statusColor(LostItemStatus s) {
    switch (s) {
      case LostItemStatus.publicado:
        return const Color(0xFF10B981); // verde esmeralda
      case LostItemStatus.enCustodia:
        return Colors.orange;
      case LostItemStatus.entregado:
        return AppColors.uctBlue;
      case LostItemStatus.cerrado:
        return Colors.grey;
    }
  }

  IconData _statusIcon(LostItemStatus s) {
    switch (s) {
      case LostItemStatus.publicado:
        return Icons.campaign_outlined;
      case LostItemStatus.enCustodia:
        return Icons.lock_outlined;
      case LostItemStatus.entregado:
        return Icons.handshake_outlined;
      case LostItemStatus.cerrado:
        return Icons.check_circle_outline;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Documentos':
        return Icons.badge_outlined;
      case 'Llaves':
        return Icons.key_outlined;
      case 'Tecnologia':
        return Icons.calculate_outlined;
      case 'Ropa':
        return Icons.checkroom_outlined;
      case 'Mochilas':
        return Icons.backpack_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Documentos':
        return Colors.blue;
      case 'Llaves':
        return Colors.amber;
      case 'Tecnologia':
        return Colors.purple;
      case 'Ropa':
        return Colors.teal;
      case 'Mochilas':
        return Colors.brown;
      default:
        return AppColors.uctBlue;
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
        content: Text(
          'Ubicando "${item.building}" (${item.campus}) en el mapa...',
        ),
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
    final int currentIndex = _allStatuses.indexOf(item.currentStatus);
    final Color accentColor = _statusColor(item.currentStatus);
    final Color catColor = _categoryColor(item.category);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Detalle del Objeto',
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
                  // Estado + ticket en la misma fila
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
                            color: accentColor.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          item.currentStatus.label,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.ticketNumber,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Icono categoria + Titulo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: catColor.withValues(alpha: 0.2),
                        child: Icon(
                          _categoryIcon(item.category),
                          color: catColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: TextStyle(
                                color: catColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Ubicacion
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.uctYellow,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          item.building,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Campus
                  Row(
                    children: [
                      const Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.uctYellow,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        item.campus,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Reportado por
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: AppColors.uctYellow,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Encontrado por ${item.reportedBy}',
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

            // ---- Foto del objeto ----
            const Text(
              'Foto del objeto',
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
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) =>
                            const _ImagePlaceholder(hasError: true),
                      )
                    : const _ImagePlaceholder(hasError: false),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Descripcion ----
            const Text(
              'Descripcion del objeto',
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
                item.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.subtitle,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ---- Donde reclamar ----
            if (item.contactInfo != null) ...[
              const Text(
                'Donde reclamar',
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
                  color: AppColors.uctBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.uctBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.uctBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.contactInfo!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.uctBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ---- Timeline de estados ----
            const Text(
              'Historial del objeto',
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

              final LostItemStatusEvent? event = item.statusHistory
                  .cast<LostItemStatusEvent?>()
                  .firstWhere((e) => e!.status == status, orElse: () => null);

              final Color dotColor = isDone
                  ? Colors.green
                  : isCurrent
                  ? accentColor
                  : Colors.grey.shade300;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  size: 15,
                                  color: isCurrent
                                      ? accentColor
                                      : Colors.grey.shade400,
                                ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: event?.note != null ? 60 : 48,
                          color: isDone
                              ? Colors.green.withValues(alpha: 0.4)
                              : Colors.grey.shade200,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: isLast ? 16 : (event?.note != null ? 60 : 48),
                      ),
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
                            if (event.note != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.fieldBorder,
                                  ),
                                ),
                                child: Text(
                                  event.note!,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.subtitle,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
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

            // ---- Boton reclamar ----
            const SizedBox(height: 8),
            if (item.currentStatus != LostItemStatus.entregado &&
                item.currentStatus != LostItemStatus.cerrado)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Contactando punto de entrega para ${item.ticketNumber}...',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.uctBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.handshake_outlined, size: 20),
                  label: const Text(
                    'Reclamar este objeto',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: placeholder para la foto del objeto
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
              'La foto se agregara al registrar el objeto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ],
      ),
    );
  }
}
