import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../data/datasources/schedule_remote_ds.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/schedule_meeting.dart';
import '../../../domain/repositories/campus_repository.dart';
import '../../../domain/repositories/identity_repository.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../login/session_required_view.dart';

class StudentMeetingsScreen extends StatelessWidget {
  const StudentMeetingsScreen({
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
    permission: AppPermission.bookConsultation,
    builder: (_) => _StudentMeetings(
      key: ObjectKey(ApiClientProvider.session.currentUser),
      repository: repository,
      campusRepository: campusRepository,
      identityRepository: identityRepository,
    ),
  );
}

typedef _StudentAgenda = ({
  List<ScheduleMeeting> meetings,
  Map<String, String> teachers,
  Map<String, String> locations,
  bool incomplete,
});

class _StudentMeetings extends StatefulWidget {
  const _StudentMeetings({
    super.key,
    this.repository,
    this.campusRepository,
    this.identityRepository,
  });
  final ScheduleRepository? repository;
  final CampusRepository? campusRepository;
  final IdentityRepository? identityRepository;
  @override
  State<_StudentMeetings> createState() => _StudentMeetingsState();
}

class _StudentMeetingsState extends State<_StudentMeetings> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late final _repository = widget.repository ?? ScheduleRemoteDataSource();
  late final _campus = widget.campusRepository ?? CampusRemoteDataSource();
  late final _identity = widget.identityRepository ?? IdentityRepositoryImpl();
  late Future<_StudentAgenda> _data = _load();

  void _checkSession() {
    if (!mounted || !_session.isAuthenticated || _session.token != _token) {
      throw StateError('La sesión cambió');
    }
  }

  Future<_StudentAgenda> _load() async {
    _checkSession();
    final id = _session.currentUser!.id;
    final meetings = await _repository.getMyMeetings();
    _checkSession();
    if (meetings.any((m) => m.studentRefId != id)) {
      throw const FormatException('Las citas no corresponden a tu cuenta.');
    }
    meetings.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final teachers = <String, String>{};
    final locations = <String, String>{};
    var incomplete = false;
    if (meetings.isNotEmpty) {
      final ids = meetings.map((m) => m.teacherRefId).toSet();
      try {
        final users = await _identity.getUsers();
        _checkSession();
        for (final user in users) {
          if (ids.contains(user.id) && user.name.trim().isNotEmpty) {
            teachers[user.id] = user.name;
          }
        }
        incomplete = ids.any((id) => !teachers.containsKey(id));
      } catch (_) {
        _checkSession();
        incomplete = true;
      }
      for (final id
          in meetings
              .map((m) => m.structureRefId)
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet()) {
        _checkSession();
        try {
          final structure = await _campus.getStructureById(id);
          _checkSession();
          if (structure.id == id && structure.name.trim().isNotEmpty) {
            locations[id] = structure.name;
          } else {
            incomplete = true;
          }
        } catch (_) {
          _checkSession();
          incomplete = true;
        }
      }
    }
    return (
      meetings: meetings,
      teachers: teachers,
      locations: locations,
      incomplete: incomplete,
    );
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  Future<void> _book() async {
    final result = await Navigator.pushNamed(context, AppRoutes.professors);
    if (!mounted || _session.token != _token) return;
    if (result == 0) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (_) => false,
        arguments: 0,
      );
    } else {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F5F8),
    appBar: AppBar(
      title: const Text('Mis citas'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Actualizar mis citas',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    bottomNavigationBar: SafeArea(
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.uctBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _book,
                  icon: const Icon(Icons.add),
                  label: const Text('Agendar consulta'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    body: FutureBuilder<_StudentAgenda>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 40,
                    color: AppColors.uctBlue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No se pudieron cargar tus citas.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final theme = Theme.of(context);
        final days = <DateTime, List<ScheduleMeeting>>{};
        for (final meeting in data.meetings) {
          final date = meeting.scheduledAt.toLocal();
          final day = DateTime(date.year, date.month, date.day);
          (days[day] ??= []).add(meeting);
        }
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.uctBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: AppColors.uctYellow,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Tu agenda',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tus consultas de los próximos 60 días, incluido hoy.',
                        style: TextStyle(color: Color(0xFFE0EBF5), height: 1.5),
                      ),
                    ],
                  ),
                ),
                if (data.incomplete) ...[
                  const SizedBox(height: 16),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline, color: AppColors.uctBlue),
                    title: Text(
                      'No se pudieron obtener algunos nombres o lugares. Tus citas siguen disponibles.',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (data.meetings.isEmpty) ...[
                  const Icon(
                    Icons.event_note,
                    size: 48,
                    color: AppColors.uctBlue,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no tienes citas para este período.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
                for (final day in days.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _dayLabel(day.key),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.uctBlue,
                      ),
                    ),
                  ),
                  for (final meeting in day.value)
                    _meeting(context, meeting, data),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );

  Widget _meeting(
    BuildContext context,
    ScheduleMeeting meeting,
    _StudentAgenda data,
  ) {
    final date = meeting.scheduledAt.toLocal();
    final end = meeting.endsAt.toLocal();
    final localizations = MaterialLocalizations.of(context);
    String time(DateTime value) => localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: true,
    );
    final (statusColor, statusIcon) = switch (meeting.status) {
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
    final theme = Theme.of(context);
    final timeBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${time(date)} – ${time(end)}',
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
          data.teachers[meeting.teacherRefId] ??
              'Nombre del docente no disponible',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.place_outlined,
                size: 18,
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                meeting.structureRefId == null ||
                        meeting.structureRefId!.isEmpty
                    ? 'Ubicación no informada'
                    : data.locations[meeting.structureRefId] ??
                          'Ubicación no disponible',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.subtitle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Chip(
          avatar: Icon(statusIcon, size: 16, color: statusColor),
          label: Text(meeting.status.label),
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: statusColor.withValues(alpha: 0.08),
          side: BorderSide.none,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
    return Card(
      elevation: 3,
      shadowColor: const Color(0x26003865),
      surfaceTintColor: Colors.transparent,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [timeBlock, const SizedBox(height: 16), details],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 128, child: timeBlock),
                const SizedBox(width: 20),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }

  String _dayLabel(DateTime day) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${weekdays[day.weekday - 1]} ${day.day} de ${months[day.month - 1]} de ${day.year}';
  }
}
