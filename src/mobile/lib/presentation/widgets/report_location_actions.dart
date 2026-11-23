import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/theme/app_colors.dart';

class ReportLocationActions extends StatelessWidget {
  const ReportLocationActions({
    super.key,
    required this.locationId,
    required this.campusId,
  });
  final String locationId;
  final String campusId;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    children: [
      TextButton.icon(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.createTicket,
          arguments: (campusId: campusId, locationId: locationId),
        ),
        icon: const Icon(Icons.report_problem_outlined),
        label: const Text('Reportar incidencia'),
        style: TextButton.styleFrom(foregroundColor: AppColors.uctBlue),
      ),
      TextButton.icon(
        onPressed: () => Navigator.pushNamed(
          context,
          AppRoutes.createLostObject,
          arguments: (campusId: campusId, locationId: locationId),
        ),
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('Reportar objeto'),
        style: TextButton.styleFrom(foregroundColor: AppColors.uctBlue),
      ),
    ],
  );
}
