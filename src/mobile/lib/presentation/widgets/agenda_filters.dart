import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/schedule_meeting.dart';

class AgendaFilters extends StatelessWidget {
  const AgendaFilters({
    super.key,
    required this.from,
    required this.to,
    required this.status,
    required this.onRangeChanged,
    required this.onStatusChanged,
  });

  final DateTime from;
  final DateTime to;
  final MeetingStatus? status;
  final ValueChanged<DateTimeRange> onRangeChanged;
  final ValueChanged<MeetingStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final last = to.subtract(const Duration(days: 1));
    String date(DateTime value) => '${value.day}/${value.month}/${value.year}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range),
            label: Text('${date(from)} – ${date(last)}'),
            onPressed: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 2, 12, 31),
                initialDateRange: DateTimeRange(start: from, end: last),
                helpText: 'Período de la agenda',
                saveText: 'Aplicar',
                cancelText: 'Volver',
              );
              if (!context.mounted || range == null) return;
              onRangeChanged(
                DateTimeRange(
                  start: range.start,
                  end: DateTime(
                    range.end.year,
                    range.end.month,
                    range.end.day + 1,
                  ),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.uctBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MeetingStatus>(
            key: ValueKey(status),
            initialValue: status,
            isExpanded: true,
            isDense: false,
            itemHeight: null,
            decoration: const InputDecoration(
              labelText: 'Estado de la cita',
              prefixIcon: Icon(Icons.filter_list, color: AppColors.uctBlue),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Todos los estados'),
              ),
              for (final value in MeetingStatus.values)
                DropdownMenuItem(value: value, child: Text(value.label)),
            ],
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}
