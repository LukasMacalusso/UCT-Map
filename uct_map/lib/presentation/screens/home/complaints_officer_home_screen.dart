import 'package:flutter/material.dart';

import '../../../application/dashboard/management_dashboard.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/reports_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/repositories/reports_repository.dart';
import '../login/session_required_view.dart';
import '../tickets/widgets/ticket_status_badge.dart';
import 'management_home_layout.dart';

class ComplaintsOfficerHomeScreen extends StatelessWidget {
  const ComplaintsOfficerHomeScreen({
    super.key,
    this.repository,
    this.active = true,
  });
  final ReportsRepository? repository;
  final bool active;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageReports,
    embedded: true,
    builder: (_) => _ComplaintsHome(
      key: ValueKey(ApiClientProvider.session.token),
      repository: repository ?? ReportsRepositoryImpl(),
      active: active,
    ),
  );
}

class _ComplaintsHome extends StatefulWidget {
  const _ComplaintsHome({
    super.key,
    required this.repository,
    required this.active,
  });
  final ReportsRepository repository;
  final bool active;
  @override
  State<_ComplaintsHome> createState() => _ComplaintsHomeState();
}

class _ComplaintsHomeState extends State<_ComplaintsHome> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late Future<ComplaintsDashboardSummary> _summary = _load();
  void _checkSession() {
    if (!mounted ||
        !_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageReports.allows(_session.currentUser?.role)) {
      throw StateError('La sesión cambió.');
    }
  }

  Future<ComplaintsDashboardSummary> _load() =>
      loadComplaintsDashboard(widget.repository, _checkSession);
  void _reload() => setState(() {
    _summary = _load();
  });
  @override
  void didUpdateWidget(covariant _ComplaintsHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _reload();
  }

  Future<void> _openReports() async {
    if (!_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageReports.allows(_session.currentUser?.role)) {
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.manageReports);
    if (mounted && _token == _session.token) _reload();
  }

  Future<void> _openReport(String id) async {
    if (id.isEmpty ||
        !_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageReports.allows(_session.currentUser?.role)) {
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.ticketDetail, arguments: id);
    if (mounted && _token == _session.token) _reload();
  }

  @override
  Widget build(BuildContext context) => ManagementHomeLayout(
    icon: Icons.assignment_outlined,
    child: FutureBuilder<ComplaintsDashboardSummary>(
      future: _summary,
      builder: (context, snapshot) {
        final summary = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              elevation: 1,
              shadowColor: AppColors.uctBlue.withValues(alpha: 0.14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Incidentes del campus',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.uctBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (snapshot.connectionState != ConnectionState.done)
                      const LinearProgressIndicator()
                    else if (snapshot.hasError) ...[
                      const Text('No se pudo cargar el resumen de incidentes.'),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Reintentar'),
                      ),
                    ] else ...[
                      Text(
                        summary!.total == null
                            ? 'Consulta los reportes registrados'
                            : '${summary.total} reportes registrados',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.uctBlue,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Consulta los reportes del campus y su estado de atención.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openReports,
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('Gestionar incidentes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (snapshot.connectionState == ConnectionState.done &&
                !snapshot.hasError) ...[
              const SizedBox(height: 28),
              Text(
                'Últimos registros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.uctBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (summary!.recent.isEmpty)
                const Text(
                  'No hay reportes registrados.',
                  style: TextStyle(color: AppColors.subtitle),
                ),
              for (final item in summary.recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        color: AppColors.uctBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.complaintDetails?.title.isNotEmpty == true
                                  ? item.complaintDetails!.title
                                  : 'Reporte de incidencia',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            TicketStatusBadge(
                              status: item.ticketType,
                              isCompact: true,
                            ),
                            if (item.id.isNotEmpty)
                              TextButton(
                                onPressed: () => _openReport(item.id),
                                child: const Text('Ver reporte'),
                              )
                            else
                              const Text(
                                'Detalle no disponible: falta el identificador.',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    ),
  );
}
