import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../data/datasources/schedule_remote_ds.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/office_hour.dart';
import '../../../domain/entities/schedule_meeting.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../login/session_required_view.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key, this.repository});
  final ScheduleRepository? repository;
  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  late final ScheduleRepository _repository =
      widget.repository ?? ScheduleRemoteDataSource();
  late Future<(List<OfficeHour>, List<ScheduleMeeting>)> _data;
  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<(List<OfficeHour>, List<ScheduleMeeting>)> _load() async {
    final session = ApiClientProvider.session;
    await session.ready;
    if (!session.isAuthenticated ||
        !AppPermission.teacherSchedule.allows(session.currentUser?.role)) {
      throw StateError('Acceso denegado');
    }
    final id = session.currentUser!.id;
    final hours = await _repository.getOfficeHours(id);
    return (hours, await _repository.getMyMeetings());
  }

  void _reload() {
    setState(() => _data = _load());
  }

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.teacherSchedule,
    builder: (_) => Scaffold(
      appBar: AppBar(
        title: const Text('Mis horarios y citas'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<(List<OfficeHour>, List<ScheduleMeeting>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _reload,
                child: const Text('No se pudo cargar la agenda. Reintentar'),
              ),
            );
          }
          final (hours, meetings) = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Horario de atención',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (hours.isEmpty) const Text('Sin horarios registrados.'),
              ...hours.map(
                (h) => ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(h.dayName),
                  subtitle: Text('${h.startTime} – ${h.endTime}'),
                ),
              ),
              const Divider(),
              Text(
                'Citas de los próximos 60 días',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (meetings.isEmpty) const Text('Sin citas registradas.'),
              ...meetings.map(
                (m) => ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(
                    '${m.scheduledAt.day}/${m.scheduledAt.month}/${m.scheduledAt.year} ${m.scheduledAt.hour.toString().padLeft(2, '0')}:${m.scheduledAt.minute.toString().padLeft(2, '0')}',
                  ),
                  subtitle: Text(
                    'Estudiante: ${m.studentRefId}\n${m.status.label}',
                  ),
                ),
              ),
              const Text(
                'Los cambios de estado de citas aún no están disponibles en Schedule.',
              ),
            ],
          );
        },
      ),
    ),
  );
}
