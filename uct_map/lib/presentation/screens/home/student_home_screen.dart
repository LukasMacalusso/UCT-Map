import 'package:flutter/material.dart';

import '../../../application/dashboard/student_dashboard.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/schedule_remote_ds.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/schedule_meeting.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../../widgets/custom_drawer.dart';
import '../login/session_required_view.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key, this.repository});
  final ScheduleRepository? repository;

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.bookConsultation,
    builder: (_) => _Dashboard(
      key: ValueKey(ApiClientProvider.session.token),
      repository: repository ?? ScheduleRemoteDataSource(),
    ),
  );
}

class _Dashboard extends StatefulWidget {
  const _Dashboard({super.key, required this.repository});
  final ScheduleRepository repository;
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  final _session = ApiClientProvider.session;
  late Future<ScheduleMeeting?> _next = loadNextStudentMeeting(
    widget.repository,
    _session.currentUser!.id,
  );

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
    final token = _session.token;
    await Navigator.pushNamed(context, AppRoutes.main, arguments: index);
    if (!mounted || token != _session.token) return;
    _reload();
  }

  void _reload() {
    setState(() {
      _next = loadNextStudentMeeting(
        widget.repository,
        _session.currentUser!.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _session.currentUser!;
    final theme = Theme.of(context);
    final name = user.name?.trim();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('UCT Map'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.uctBlue,
        actions: [
          IconButton(
            tooltip: 'Mi perfil',
            onPressed: () => _tab(4),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      drawer: CustomDrawer(currentIndex: -1, onSelectTab: _tab),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFFE1EBF8),
                    child: Icon(Icons.person_outline, color: AppColors.uctBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name == null || name.isEmpty
                              ? '¡Hola!'
                              : '¡Hola, $name!',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(user.email, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _tab(1),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(18),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar edificio, sala o servicio'),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.event_available,
                            color: AppColors.uctGold,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Próxima consulta',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.uctBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<ScheduleMeeting?>(
                        future: _next,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done)
                            return const LinearProgressIndicator();
                          if (snapshot.hasError)
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No se pudo cargar tu próxima consulta.',
                                ),
                                TextButton.icon(
                                  onPressed: _reload,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reintentar'),
                                ),
                              ],
                            );
                          final meeting = snapshot.data;
                          if (meeting == null)
                            return const Text(
                              'No tienes consultas próximas. Puedes consultar la atención disponible en el directorio.',
                            );
                          final date = meeting.scheduledAt.toLocal();
                          final time = MaterialLocalizations.of(context)
                              .formatTimeOfDay(
                                TimeOfDay.fromDateTime(date),
                                alwaysUse24HourFormat: true,
                              );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${date.day}/${date.month}/${date.year} · $time',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${meeting.durationMinutes} minutos · ${meeting.status.label}',
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _open(AppRoutes.myMeetings),
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: const Text('Ver mis citas'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Accesos rápidos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final single =
                      constraints.maxWidth < 320 ||
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  final width = single
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _access(
                        width,
                        Icons.school_outlined,
                        'Directorio docente',
                        'Horarios de atención',
                        const Color(0xFFE1EBF8),
                        () => _open(AppRoutes.professors),
                      ),
                      _access(
                        width,
                        Icons.map_outlined,
                        'Explorar campus',
                        'Abrir mapa',
                        const Color(0xFFE1EBF8),
                        () => _tab(0),
                      ),
                      _access(
                        width,
                        Icons.inventory_2_outlined,
                        'Objetos perdidos',
                        'Consultar o reportar',
                        const Color(0xFFFFE8A3),
                        () => _tab(2),
                      ),
                      _access(
                        width,
                        Icons.report_problem_outlined,
                        'Reportar incidencia',
                        'Infraestructura y espacios',
                        const Color(0xFFFFDDD7),
                        () => _tab(3),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index > 0) _tab([0, 0, 1, 3, 4][index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _access(
    double width,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) => SizedBox(
    width: width,
    child: Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.uctBlue),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ),
    ),
  );
}
