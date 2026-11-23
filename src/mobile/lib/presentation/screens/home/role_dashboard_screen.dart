import '../../../domain/entities/dashboard_academic_content.dart';

import 'package:flutter/material.dart';

import '../../../application/dashboard/student_dashboard.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/schedule_remote_ds.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/schedule_meeting.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import 'dashboard_academic_sections.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/app_navigation_bar.dart';
import '../login/session_required_view.dart';

class RoleDashboardScreen extends StatelessWidget {
  const RoleDashboardScreen({
    super.key,
    this.repository,
    this.academicContent,
    this.embedded = false,
    this.active = true,
    this.onNavigateToTab,
    required this.permission,
  });
  final AppPermission permission;
  final ScheduleRepository? repository;
  final DashboardAcademicContent? academicContent;
  final bool embedded;
  final bool active;
  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: permission,
    embedded: embedded,
    builder: (_) => _Dashboard(
      key: ValueKey(ApiClientProvider.session.token),
      repository: repository ?? ScheduleRemoteDataSource(),
      teacher: permission == AppPermission.teacherSchedule,
      academicContent: academicContent,
      embedded: embedded,
      active: active,
      onNavigateToTab: onNavigateToTab,
    ),
  );
}

class _Dashboard extends StatefulWidget {
  const _Dashboard({
    super.key,
    required this.repository,
    required this.teacher,
    this.academicContent,
    required this.embedded,
    required this.active,
    this.onNavigateToTab,
  });
  final bool teacher;
  final DashboardAcademicContent? academicContent;
  final bool embedded;
  final bool active;
  final ValueChanged<int>? onNavigateToTab;
  final ScheduleRepository repository;
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  final _session = ApiClientProvider.session;
  Future<DashboardDay> _load() {
    final token = _session.token;
    return loadDashboardDay(
      schedule: widget.repository,
      identity: IdentityRepositoryImpl(),
      campus: CampusRemoteDataSource(),
      userId: _session.currentUser!.id,
      teacher: widget.teacher,
      checkSession: () {
        if (!_session.isAuthenticated || _session.token != token)
          throw StateError('La sesión cambió.');
      },
    );
  }

  late Future<DashboardDay> _data = _load();

  Future<void> _open(String route) async {
    final token = _session.token;
    final result = await Navigator.pushNamed(context, route);
    if (!mounted || token != _session.token) return;
    if (result == 0) {
      _tab(0);
    } else {
      _reload();
    }
  }

  Future<void> _tab(int index) async {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(index);
      return;
    }
    final token = _session.token;
    await Navigator.pushNamed(context, AppRoutes.main, arguments: index);
    if (!mounted || token != _session.token) return;
    _reload();
  }

  @override
  void didUpdateWidget(covariant _Dashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _reload();
  }

  void _reload() {
    setState(() {
      _data = _load();
    });
  }

  String _time(DateTime date) => MaterialLocalizations.of(context)
      .formatTimeOfDay(
        TimeOfDay.fromDateTime(date.toLocal()),
        alwaysUse24HourFormat: true,
      );

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.uctBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.uctBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _meeting(
    ScheduleMeeting meeting,
    DashboardDay day, {
    bool featured = false,
  }) {
    final date = meeting.scheduledAt.toLocal();
    final person =
        day.names[widget.teacher
            ? meeting.studentRefId
            : meeting.teacherRefId] ??
        (widget.teacher ? 'Estudiante no disponible' : 'Docente no disponible');
    final place =
        day.locations[meeting.structureRefId] ??
        (meeting.structureRefId == null
            ? 'Lugar no informado'
            : 'Lugar no disponible');
    final theme = Theme.of(context);
    final time = '${_time(date)} – ${_time(meeting.endsAt)}';
    return Padding(
      padding: EdgeInsets.only(bottom: featured ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured) ...[
            Text(
              person,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.uctBlue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 22,
                  color: AppColors.uctBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.uctBlue,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.uctBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.uctBlue,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              time,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.uctBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              person,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(place, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
          ],
          if (!featured)
            Text(
              '${meeting.durationMinutes} minutos · ${meeting.status.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF526174),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(MeetingStatus status) {
    final (color, icon) = switch (status) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              status.label,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextHeader(ScheduleMeeting? meeting) {
    final title = Row(
      children: [
        const Icon(Icons.event_available, color: AppColors.uctGold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Próxima consulta',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.uctBlue,
            ),
          ),
        ),
      ],
    );
    if (meeting == null) return title;
    return LayoutBuilder(
      builder: (context, constraints) {
        final status = _statusBadge(meeting.status);
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 22) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(alignment: Alignment.topRight, child: status),
              const SizedBox(height: 12),
              title,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: title,
              ),
            ),
            const SizedBox(width: 12),
            status,
          ],
        );
      },
    );
  }

  Widget _scheduleSummary(DashboardDay day) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        elevation: 1,
        shadowColor: AppColors.uctBlue.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _nextHeader(day.next),
              const SizedBox(height: 20),
              if (day.next != null)
                _meeting(day.next!, day, featured: true)
              else
                Text(
                  widget.teacher
                      ? 'No tienes consultas próximas. Revisa tu agenda y tus bloques de atención.'
                      : 'No tienes consultas próximas. Puedes consultar la atención disponible en el directorio.',
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _open(
                    widget.teacher
                        ? AppRoutes.teacherSchedule
                        : AppRoutes.myMeetings,
                  ),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    widget.teacher ? 'Ver mi agenda' : 'Ver mis citas',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      _section('Otras consultas de hoy', Icons.today_outlined, [
        if (day.otherToday.isEmpty)
          const Text(
            'No tienes otras consultas pendientes para hoy.',
            style: TextStyle(fontSize: 14, color: Color(0xFF526174)),
          ),
        for (final meeting in day.otherToday) _meeting(meeting, day),
      ]),
      if (widget.teacher)
        _section('Atención de hoy', Icons.schedule_outlined, [
          if (day.hoursUnavailable) ...[
            const Text('No se pudo cargar tu horario de atención.'),
            TextButton(
              onPressed: _reload,
              child: const Text('Reintentar atención'),
            ),
          ] else if (day.hours.isEmpty)
            const Text(
              'No tienes bloques de atención para hoy.',
              style: TextStyle(fontSize: 14, color: Color(0xFF526174)),
            )
          else ...[
            const Text(
              'Horario de atención; no indica horas libres para reservar.',
            ),
            const SizedBox(height: 12),
            for (final hour in day.hours)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${hour.startLabel} – ${hour.endLabel}\n${day.locations[hour.structureRefId] ?? (hour.structureRefId == null ? 'Lugar no informado' : 'Lugar no disponible')}',
                ),
              ),
          ],
        ]),
      if (day.labelsIncomplete)
        TextButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar nombres y lugares'),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final user = _session.currentUser!;
    final theme = Theme.of(context);
    final name = user.name?.trim();
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE1EBF8),
                  child: Icon(Icons.person_outline, color: AppColors.uctBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name == null || name.isEmpty
                            ? '¡Hola!'
                            : '¡Hola, $name!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF526174),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FutureBuilder<DashboardDay>(
              future: _data,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done)
                  return const LinearProgressIndicator();
                if (snapshot.hasError)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('No se pudo cargar tu resumen del día.'),
                      TextButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  );
                return _scheduleSummary(snapshot.data!);
              },
            ),
            DashboardAcademicSections(
              content: widget.academicContent,
              userId: user.id,
            ),
          ],
        ),
      ),
    );
    if (widget.embedded) {
      return ColoredBox(color: const Color(0xFFF6F7F9), child: body);
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Text(widget.teacher ? 'Inicio docente' : 'UCT Map'),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            onPressed: () => _tab(4),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      drawer: CustomDrawer(currentIndex: -1, onSelectTab: _tab),
      body: body,
      bottomNavigationBar: AppNavigationBar(
        currentTab: 5,
        onSelectTab: (tab) {
          if (tab != 5) _tab(tab);
        },
      ),
    );
  }
}
