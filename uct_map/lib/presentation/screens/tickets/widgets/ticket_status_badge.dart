import 'package:flutter/material.dart';
import '../../../../domain/entities/ticket.dart';

/// Badge visual para el estado general del Ticket:
/// 0: Pending (Ámbar)
/// 1: In_Process (Azul)
/// 2: Resolved (Verde Esmeralda)
/// 3: Dismissed (Gris)
class TicketStatusBadge extends StatelessWidget {
  final TicketStatus status;
  final bool isCompact;

  const TicketStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: isCompact ? 12 : 14, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeStyle _config(TicketStatus s) {
    switch (s) {
      case TicketStatus.pending:
        return _BadgeStyle(
          textColor: const Color(0xFFB45309), // amber-700
          backgroundColor: const Color(0xFFFEF3C7), // amber-100
          borderColor: const Color(0xFFFDE68A),
          icon: Icons.hourglass_top_rounded,
        );
      case TicketStatus.inProcess:
        return _BadgeStyle(
          textColor: const Color(0xFF1D4ED8), // blue-700
          backgroundColor: const Color(0xFFDBEAFE), // blue-100
          borderColor: const Color(0xFFBFDBFE),
          icon: Icons.autorenew_rounded,
        );
      case TicketStatus.resolved:
        return _BadgeStyle(
          textColor: const Color(0xFF047857), // emerald-700
          backgroundColor: const Color(0xFFD1FAE5), // emerald-100
          borderColor: const Color(0xFFA7F3D0),
          icon: Icons.check_circle_rounded,
        );
      case TicketStatus.dismissed:
        return _BadgeStyle(
          textColor: const Color(0xFF4B5563), // gray-600
          backgroundColor: const Color(0xFFF3F4F6), // gray-100
          borderColor: const Color(0xFFE5E7EB),
          icon: Icons.block_rounded,
        );
    }
  }
}

/// Badge visual para el estado de Queja / Reclamo (Complainenum):
/// 0: Claim (Reclamo - Púrpura)
/// 1: Found (Hallazgo - Teal)
/// 2: Match (Coincidencia - Naranja)
/// 3: Pickup (Retiro - Verde)
class ComplaintStatusBadge extends StatelessWidget {
  final ComplaintStatus status;
  final bool isCompact;

  const ComplaintStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: isCompact ? 12 : 13, color: config.textColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeStyle _config(ComplaintStatus s) {
    switch (s) {
      case ComplaintStatus.claim:
        return _BadgeStyle(
          textColor: const Color(0xFF6D28D9), // purple-700
          backgroundColor: const Color(0xFFEDE9FE), // purple-100
          borderColor: const Color(0xFFDDD6FE),
          icon: Icons.announcement_outlined,
        );
      case ComplaintStatus.found:
        return _BadgeStyle(
          textColor: const Color(0xFF0F766E), // teal-700
          backgroundColor: const Color(0xFFCCFBF1), // teal-100
          borderColor: const Color(0xFF99F6E4),
          icon: Icons.search_rounded,
        );
      case ComplaintStatus.match:
        return _BadgeStyle(
          textColor: const Color(0xFFC2410C), // orange-700
          backgroundColor: const Color(0xFFFFEDD5), // orange-100
          borderColor: const Color(0xFFFED7AA),
          icon: Icons.compare_arrows_rounded,
        );
      case ComplaintStatus.pickup:
        return _BadgeStyle(
          textColor: const Color(0xFF15803D), // green-700
          backgroundColor: const Color(0xFFDCFCE7), // green-100
          borderColor: const Color(0xFFBBF7D0),
          icon: Icons.handshake_outlined,
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
