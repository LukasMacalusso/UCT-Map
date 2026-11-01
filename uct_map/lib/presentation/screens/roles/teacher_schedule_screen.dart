import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../data/datasources/schedule_remote_ds.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/office_hour.dart';
import '../../../domain/entities/schedule_meeting.dart';
import '../../../domain/repositories/campus_repository.dart';
import '../../../domain/repositories/identity_repository.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../../widgets/office_hour_card.dart';
import '../login/session_required_view.dart';

class TeacherScheduleScreen extends StatelessWidget {
  const TeacherScheduleScreen({
    super.key,
    this.repository,
    this.campusRepository,
    this.identityRepository,
  });

  final ScheduleRepository? repository;
  final CampusRepository? campusRepository;
  final IdentityRepository? identityRepository;

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.teacherSchedule,
    builder: (_) => _TeacherAgenda(
      key: ObjectKey(ApiClientProvider.session.currentUser),
      repository: repository,
      campusRepository: campusRepository,
      identityRepository: identityRepository,
    ),
  );
}

typedef _Agenda = ({
  List<OfficeHour> hours,
  List<ScheduleMeeting> meetings,
  Map<String, String> names,
  Map<String, String> locations,
  bool incompleteLabels,
});

class _TeacherAgenda extends StatefulWidget {
  const _TeacherAgenda({
    super.key,
    this.repository,
    this.campusRepository,
    this.identityRepository,
  });
  final ScheduleRepository? repository;
  final CampusRepository? campusRepository;
  final IdentityRepository? identityRepository;

  @override
  State<_TeacherAgenda> createState() => _TeacherAgendaState();
}

class _TeacherAgendaState extends State<_TeacherAgenda> {
  late final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late final _repository = widget.repository ?? ScheduleRemoteDataSource();
  late final _campus = widget.campusRepository ?? CampusRemoteDataSource();
  late final _identity = widget.identityRepository ?? IdentityRepositoryImpl();
  late Future<_Agenda> _data = _load();

  void _checkSession() {
    if (!mounted || !_session.isAuthenticated || _session.token != _token) {
      throw StateError('La sesión cambió');
    }
  }

  Future<_Agenda> _load() async {
    _checkSession();
    final id = _session.currentUser!.id;
    final hours = await _repository.getOfficeHours(id);
    _checkSession();
    final meetings = await _repository.getMyMeetings();
    _checkSession();
    if (hours.any((h) => h.teacherRefId != id) ||
        meetings.any((m) => m.teacherRefId != id)) {
      throw const FormatException('La agenda no corresponde al docente');
    }
    hours.sort((a, b) {
      final day = a.dayOfWeek.compareTo(b.dayOfWeek);
      return day == 0 ? a.startTime.compareTo(b.startTime) : day;
    });
    meetings.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final names = <String, String>{};
    final locations = <String, String>{};
    var incompleteLabels = false;
    try {
      final users = await _identity.getUsers();
      _checkSession();
      final ids = meetings.map((m) => m.studentRefId).toSet();
      for (final user in users) {
        if (ids.contains(user.id) && user.name.trim().isNotEmpty) {
          names[user.id] = user.name;
        }
      }
    } catch (_) {
      _checkSession();
      incompleteLabels = true;
    }
    final structures = {
      ...hours.map((h) => h.structureRefId),
      ...meetings.map((m) => m.structureRefId),
    }.whereType<String>().where((id) => id.isNotEmpty);
    for (final structureId in structures) {
      _checkSession();
      try {
        final structure = await _campus.getStructureById(structureId);
        _checkSession();
        if (structure.id == structureId && structure.name.trim().isNotEmpty) {
          locations[structureId] = structure.name;
        } else {
          incompleteLabels = true;
        }
      } catch (_) {
        _checkSession();
        incompleteLabels = true;
      }
    }
    return (
      hours: hours,
      meetings: meetings,
      names: names,
      locations: locations,
      incompleteLabels: incompleteLabels,
    );
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F5F8),
    appBar: AppBar(
      title: const Text('Mis horarios y citas'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Actualizar agenda',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<_Agenda>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('No se pudo cargar la agenda. Reintentar'),
            ),
          );
        }
        final data = snapshot.data!;
        final upcoming = data.meetings.where(
          (m) => m.isActive && !m.scheduledAt.isBefore(DateTime.now()),
        );
        final theme = Theme.of(context);
        final next = upcoming.firstOrNull;
        final days = <DateTime, List<ScheduleMeeting>>{};
        for (final meeting in data.meetings.where(
          (meeting) => meeting != next,
        )) {
          final date = meeting.scheduledAt.toLocal();
          (days[DateUtils.dateOnly(date)] ??= []).add(meeting);
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (data.incompleteLabels)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'No se pudieron cargar algunos nombres o lugares. Tus horarios y citas siguen disponibles.',
                    ),
                  ),
                _heading(context, 'Próxima cita', Icons.event_available),
                if (next == null)
                  const Text('No hay citas próximas activas.')
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _dayLabel(next.scheduledAt.toLocal()),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.uctBlue,
                      ),
                    ),
                  ),
                  _meetingCard(context, next, data),
                ],
                _heading(
                  context,
                  'Otras citas de los próximos 60 días',
                  Icons.event_note,
                ),
                if (days.isEmpty)
                  Text(
                    data.meetings.isEmpty
                        ? 'Sin citas registradas.'
                        : 'No hay más citas en este período.',
                  ),
                for (final day in days.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Text(
                      _dayLabel(day.key),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.uctBlue,
                      ),
                    ),
                  ),
                  for (final meeting in day.value)
                    _meetingCard(context, meeting, data),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                ExpansionTile(
                  key: const PageStorageKey('teacher-office-hours'),
                  initiallyExpanded: data.meetings.isEmpty,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 12),
                  leading: const Icon(Icons.schedule, color: AppColors.uctBlue),
                  title: Text(
                    'Horario de atención',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.uctBlue,
                    ),
                  ),
                  subtitle: const Text('Bloques semanales de atención'),
                  children: [
                    if (data.hours.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Sin horarios registrados.'),
                      ),
                    for (final hour in data.hours)
                      OfficeHourCard(
                        hour: hour,
                        location:
                            data.locations[hour.structureRefId] ??
                            (hour.structureRefId == null ||
                                    hour.structureRefId!.isEmpty
                                ? 'Ubicación no informada'
                                : 'Ubicación no disponible'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _heading(BuildContext context, String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Icon(icon, color: AppColors.uctBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.uctBlue,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _meetingCard(
    BuildContext context,
    ScheduleMeeting meeting,
    _Agenda data,
  ) {
    final date = meeting.scheduledAt.toLocal();
    final theme = Theme.of(context);
    final (color, icon) = switch (meeting.status) {
      MeetingStatus.pending => (const Color(0xFF745500), Icons.schedule),
      MeetingStatus.confirmed => (
        const Color(0xFF166445),
        Icons.check_circle_outline,
      ),
      MeetingStatus.cancelled => (
        const Color(0xFF9D3030),
        Icons.cancel_outlined,
      ),
      MeetingStatus.completed => (AppColors.subtitle, Icons.task_alt),
    };
    final time = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_time(context, date)} – ${_time(context, meeting.endsAt.toLocal())}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.uctBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${meeting.durationMinutes} minutos',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.subtitle),
        ),
      ],
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estudiante: ${data.names[meeting.studentRefId] ?? "Nombre no disponible"}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.place_outlined,
              size: 18,
              color: AppColors.subtitle,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                data.locations[meeting.structureRefId] ??
                    (meeting.structureRefId == null ||
                            meeting.structureRefId!.isEmpty
                        ? 'Ubicación no informada'
                        : 'Ubicación no disponible'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Chip(
          avatar: Icon(icon, size: 16, color: color),
          label: Text(meeting.status.label),
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: color.withValues(alpha: 0.08),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: const Color(0x26003865),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [time, const SizedBox(height: 12), details],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 128, child: time),
                const SizedBox(width: 16),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }

  String _time(BuildContext context, DateTime date) => MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true);

  String _dayLabel(DateTime date) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return '${days[date.weekday - 1]} ${date.day}/${date.month}/${date.year}';
  }
}
