import 'package:flutter/material.dart';
import '../../../../domain/entities/lost_object.dart';

/// Componente visual tipo badge/tag de color según el estado del objeto perdido:
/// - Pending (0): Amarillo / Ámbar
/// - In_Process (1): Azul UCT / Celeste
/// - Resolved (2): Verde esmeralda
/// - Canceled (3): Gris / Neutral
class LostObjectStatusBadge extends StatelessWidget {
  final LostObjectStatus status;
  final bool isCompact;

  const LostObjectStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: isCompact ? 12 : 14,
            color: config.textColor,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeStyle _statusConfig(LostObjectStatus s) {
    switch (s) {
      case LostObjectStatus.pending:
        return _BadgeStyle(
          textColor: const Color(0xFFB45309), // amber-700
          backgroundColor: const Color(0xFFFEF3C7), // amber-100
          borderColor: const Color(0xFFFDE68A),
          icon: Icons.hourglass_top_rounded,
        );
      case LostObjectStatus.inProcess:
        return _BadgeStyle(
          textColor: const Color(0xFF1D4ED8), // blue-700
          backgroundColor: const Color(0xFFDBEAFE), // blue-100
          borderColor: const Color(0xFFBFDBFE),
          icon: Icons.autorenew_rounded,
        );
      case LostObjectStatus.resolved:
        return _BadgeStyle(
          textColor: const Color(0xFF047857), // emerald-700
          backgroundColor: const Color(0xFFD1FAE5), // emerald-100
          borderColor: const Color(0xFFA7F3D0),
          icon: Icons.check_circle_rounded,
        );
      case LostObjectStatus.canceled:
        return _BadgeStyle(
          textColor: const Color(0xFF4B5563), // gray-600
          backgroundColor: const Color(0xFFF3F4F6), // gray-100
          borderColor: const Color(0xFFE5E7EB),
          icon: Icons.cancel_rounded,
        );
    }
  }
}

class _BadgeStyle {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  _BadgeStyle({
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}
