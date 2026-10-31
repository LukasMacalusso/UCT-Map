import 'package:flutter/material.dart';

import '../../../application/session/session_controller.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/schedule_remote_ds.dart';
import '../../../domain/entities/professor.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../login/session_required_view.dart';

/// Pantalla Directorio de Profesores conectada al Schedule Service (ms.svg).
class ProfessorsScreen extends StatefulWidget {
  const ProfessorsScreen({
    super.key,
    this.onNavigateToTab,
    this.scheduleRepository,
  });

  final Function(int)? onNavigateToTab;
  final ScheduleRepository? scheduleRepository;

  @override
  State<ProfessorsScreen> createState() => _ProfessorsScreenState();
}

class _ProfessorsScreenState extends State<ProfessorsScreen> {
  late final ScheduleRepository _repository;
  List<Professor> _professors = [];
  bool _loading = true;
  String _searchQuery = '';

  SessionController get _session => ApiClientProvider.session;
  bool get _canBook =>
      _session.isAuthenticated &&
      AppPermission.bookConsultation.allows(_session.currentUser?.role);

  @override
  void initState() {
    super.initState();
    _repository = widget.scheduleRepository ?? ScheduleRemoteDataSource();
    _loadProfessors();
  }

  Future<void> _loadProfessors() async {
    setState(() => _loading = true);
    try {
      final list = await _repository.getProfessors();
      if (mounted) {
        setState(() {
          _professors = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Professor> get _filteredProfessors {
    final base = _professors.isNotEmpty
        ? _professors
        : ScheduleRemoteDataSource.fallbackProfessors;
    if (_searchQuery.trim().isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.department.toLowerCase().contains(q) ||
          p.office.toLowerCase().contains(q);
    }).toList();
  }

  void _showBookingDialog(Professor prof) {
    if (!_canBook) return;
    final bookingToken = _session.token;
    String? bookingError;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return SessionRequiredView(
          permission: AppPermission.bookConsultation,
          builder: (_) => StatefulBuilder(
            builder: (context, setDialogState) {
              if (_session.token != bookingToken) {
                return AlertDialog(
                  title: const Text('La sesión cambió'),
                  content: const Text(
                    'Vuelve a abrir la reserva desde tu cuenta.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cerrar'),
                    ),
                  ],
                );
              }
              return AlertDialog(
                title: Text('Agendar Cita con ${prof.name}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bookingError != null)
                      Text(
                        bookingError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    Text(
                      'Departamento: ${prof.department}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF003865),
                      ),
                      title: Text(
                        'Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: TextButton(
                        child: const Text('Cambiar'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (picked != null && context.mounted) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.access_time,
                        color: Color(0xFF003865),
                      ),
                      title: Text(
                        'Hora: ${selectedTime.format(context)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: TextButton(
                        child: const Text('Cambiar'),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (picked != null && context.mounted) {
                            setDialogState(() => selectedTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003865),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (!_canBook || _session.token != bookingToken) return;
                      final scheduledAt = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      final matchingHours = prof.officeHours.where((h) {
                        final start = h.startTime
                            .split(':')
                            .map(int.parse)
                            .toList();
                        final end = h.endTime
                            .split(':')
                            .map(int.parse)
                            .toList();
                        final minute =
                            scheduledAt.hour * 60 + scheduledAt.minute;
                        return h.dayOfWeek == scheduledAt.weekday &&
                            minute >= start[0] * 60 + start[1] &&
                            minute + 30 <= end[0] * 60 + end[1];
                      }).toList();
                      if (matchingHours.isEmpty) {
                        setDialogState(
                          () => bookingError = 'Selecciona una cita de 30 minutos dentro del horario de atención.',
                        );
                        return;
                      }
                      Navigator.pop(dialogCtx);
                      try {
                        await _repository.createMeeting(
                          teacherRefId: prof.id,
                          structureRefId:
                              matchingHours.first.structureRefId ?? '',
                          scheduledAt: scheduledAt,
                        );
                        if (mounted && _session.token == bookingToken) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Cita solicitada exitosamente con ${prof.name}.',
                              ),
                            ),
                          );
                        }
                      } catch (_) {
                        if (mounted && _session.token == bookingToken) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No se pudo agendar la cita. Intenta nuevamente.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Confirmar Cita'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _goToMap(BuildContext context, String profName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ubicando oficina de $profName en el mapa...'),
        duration: const Duration(seconds: 2),
      ),
    );

    if (widget.onNavigateToTab != null) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, 0);
      }
      widget.onNavigateToTab!(0);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, 0);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.initial, arguments: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) => _buildDirectory(context),
    );
  }

  Widget _buildDirectory(BuildContext context) {
    final list = _filteredProfessors;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Directorio de Profesores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar profesor por nombre o departamento...',
                prefixIcon: const Icon(Icons.search, color: AppColors.uctBlue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.uctBlue,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                ? const Center(child: Text('No se encontraron profesores.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final prof = list[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.fieldBorder),
                        ),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.uctBlue.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.uctBlue,
                            ),
                          ),
                          title: Text(
                            prof.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          subtitle: Text(
                            prof.department,
                            style: const TextStyle(
                              color: AppColors.subtitle,
                              fontSize: 13,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.meeting_room,
                                        size: 20,
                                        color: AppColors.uctGold,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ubicación: ${prof.office}',
                                          style: const TextStyle(
                                            color: AppColors.ink,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email,
                                        size: 20,
                                        color: AppColors.uctBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Correo: ${prof.email}',
                                          style: const TextStyle(
                                            color: AppColors.ink,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (prof.officeHours.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Horarios de Atención:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...prof.officeHours.map(
                                      (h) => Text(
                                        '• ${h.dayName}: ${h.startTime} - ${h.endTime}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _goToMap(context, prof.name),
                                        icon: const Icon(Icons.map_outlined),
                                        label: const Text('Ver en Mapa'),
                                      ),
                                      if (_canBook) ...[
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF003865,
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () =>
                                              _showBookingDialog(prof),
                                          icon: const Icon(
                                            Icons.calendar_month,
                                          ),
                                          label: const Text('Agendar Cita'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
