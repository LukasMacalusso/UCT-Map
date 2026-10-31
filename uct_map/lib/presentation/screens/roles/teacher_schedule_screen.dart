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
      final ids = {id, ...meetings.map((m) => m.studentRefId)};
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
    backgroundColor: const Color(0xFFF9F9F9),
    appBar: AppBar(
      title: const Text('Mis horarios y citas'),
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
        final user = _session.currentUser!;
        final upcoming = data.meetings.where(
          (m) => m.isActive && !m.scheduledAt.isBefore(DateTime.now()),
        );
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.fieldBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Chip(
                      avatar: Icon(Icons.school_outlined),
                      label: Text('Docente'),
                    ),
                    Text(
                      data.names[user.id] ?? user.name ?? user.email,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(user.email),
                    const SizedBox(height: 8),
                    const Text('Tu atención semanal y tus citas'),
                  ],
                ),
              ),
            ),
            if (data.incompleteLabels)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No se pudieron cargar algunos nombres. Se muestran las referencias disponibles.',
                ),
              ),
            _heading(context, 'Próxima cita', Icons.event_available),
            if (upcoming.isEmpty)
              const Text('No hay citas próximas activas.')
            else
              _meetingCard(context, upcoming.first, data),
            _heading(context, 'Horario de atención', Icons.schedule),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text('Bloques semanales de atención, sin fecha fija.'),
            ),
            if (data.hours.isEmpty) const Text('Sin horarios registrados.'),
            ...data.hours.map(
              (h) => OfficeHourCard(
                hour: h,
                location: data.locations[h.structureRefId],
              ),
            ),
            _heading(
              context,
              'Citas de los próximos 60 días',
              Icons.event_note,
            ),
            if (data.meetings.isEmpty) const Text('Sin citas registradas.'),
            ...data.meetings.map((m) => _meetingCard(context, m, data)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Este apartado permite consultar la agenda. Los cambios de estado de citas no están habilitados aquí.',
              ),
            ),
          ],
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
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
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
    final time = TimeOfDay.fromDateTime(date).format(context);
    final location =
        data.locations[meeting.structureRefId] ??
        (meeting.structureRefId.isEmpty
            ? 'Ubicación no informada'
            : 'Estructura: ${meeting.structureRefId}');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.fieldBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date.day}/${date.month}/${date.year} · $time',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Estudiante: ${data.names[meeting.studentRefId] ?? meeting.studentRefId}',
            ),
            Text(location),
            Chip(label: Text(meeting.status.label)),
          ],
        ),
      ),
    );
  }
}
