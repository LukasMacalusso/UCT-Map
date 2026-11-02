import 'package:flutter/material.dart';

import '../../../domain/entities/dashboard_academic_content.dart';
import '../../../core/theme/app_colors.dart';

class DashboardAcademicSections extends StatelessWidget {
  const DashboardAcademicSections({
    super.key,
    required this.content,
    required this.userId,
  });
  final DashboardAcademicContent? content;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final data = content;
    if (data == null || data.userId != userId) return const SizedBox.shrink();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day + 1);
    final classes =
        data.classes
            ?.where((c) => c.startsAt.isBefore(end) && c.endsAt.isAfter(start))
            .toList()
          ?..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    String time(DateTime date) => MaterialLocalizations.of(context)
        .formatTimeOfDay(
          TimeOfDay.fromDateTime(date.toLocal()),
          alwaysUse24HourFormat: true,
        );
    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.uctBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (classes != null)
          section('Clases de hoy', [
            if (classes.isEmpty) const Text('No tienes clases para hoy.'),
            for (final item in classes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.school_outlined,
                  color: AppColors.uctBlue,
                ),
                title: Text(item.title),
                subtitle: Text(
                  '${time(item.startsAt)} – ${time(item.endsAt)}\n${item.location}',
                ),
              ),
          ]),
        if (data.notices != null)
          section('Avisos del campus', [
            if (data.notices!.isEmpty) const Text('No hay avisos disponibles.'),
            for (final notice in data.notices!)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(notice.message),
                  ],
                ),
              ),
          ]),
      ],
    );
  }
}
