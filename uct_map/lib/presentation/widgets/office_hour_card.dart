import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/office_hour.dart';

class OfficeHourCard extends StatelessWidget {
  const OfficeHourCard({super.key, required this.hour, this.location});

  final OfficeHour hour;
  final String? location;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.fieldBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 84,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.uctBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hour.dayName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.uctBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hour.startLabel} – ${hour.endLabel}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.meeting_room_outlined,
                  color: AppColors.uctBlue,
                ),
                Text(
                  location ??
                      (hour.structureRefId == null ||
                              hour.structureRefId!.isEmpty
                          ? 'Ubicación no informada'
                          : 'Estructura: ${hour.structureRefId}'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
