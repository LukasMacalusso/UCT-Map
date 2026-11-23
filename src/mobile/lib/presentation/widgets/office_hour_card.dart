import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/office_hour.dart';

class OfficeHourCard extends StatelessWidget {
  const OfficeHourCard({super.key, required this.hour, this.location});

  final OfficeHour hour;
  final String? location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final day = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hour.dayName,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.uctBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${hour.startLabel} – ${hour.endLabel}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 20,
              color: AppColors.subtitle,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                location ??
                    (hour.structureRefId == null || hour.structureRefId!.isEmpty
                        ? 'Ubicación no informada'
                        : 'Estructura: ${hour.structureRefId}'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: const Color(0x26003865),
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [day, const SizedBox(height: 16), details],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 100, child: day),
                const SizedBox(width: 16),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }
}
