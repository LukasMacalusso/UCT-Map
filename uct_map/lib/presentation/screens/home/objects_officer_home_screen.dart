import 'package:flutter/material.dart';

import '../../../application/dashboard/management_dashboard.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/lost_objects_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/repositories/lost_objects_repository.dart';
import '../login/session_required_view.dart';
import '../lost_objects/widgets/lost_object_status_badge.dart';
import 'management_home_layout.dart';

class ObjectsOfficerHomeScreen extends StatelessWidget {
  const ObjectsOfficerHomeScreen({
    super.key,
    this.repository,
    this.active = true,
  });
  final LostObjectsRepository? repository;
  final bool active;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageObjects,
    embedded: true,
    builder: (_) => _ObjectsHome(
      key: ValueKey(ApiClientProvider.session.token),
      repository: repository ?? LostObjectsRepositoryImpl(),
      active: active,
    ),
  );
}

class _ObjectsHome extends StatefulWidget {
  const _ObjectsHome({
    super.key,
    required this.repository,
    required this.active,
  });
  final LostObjectsRepository repository;
  final bool active;
  @override
  State<_ObjectsHome> createState() => _ObjectsHomeState();
}

class _ObjectsHomeState extends State<_ObjectsHome> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late Future<ObjectsDashboardSummary> _summary = _load();
  void _checkSession() {
    if (!mounted ||
        !_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageObjects.allows(_session.currentUser?.role)) {
      throw StateError('La sesión cambió.');
    }
  }

  Future<ObjectsDashboardSummary> _load() =>
      loadObjectsDashboard(widget.repository, _checkSession);
  void _reload() => setState(() {
    _summary = _load();
  });
  @override
  void didUpdateWidget(covariant _ObjectsHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _reload();
  }

  Future<void> _openObjects() async {
    if (!_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageObjects.allows(_session.currentUser?.role)) {
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.manageObjects);
    if (mounted && _token == _session.token) _reload();
  }

  @override
  Widget build(BuildContext context) => ManagementHomeLayout(
    icon: Icons.inventory_2_outlined,
    child: FutureBuilder<ObjectsDashboardSummary>(
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
                      'Objetos perdidos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.uctBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (snapshot.connectionState != ConnectionState.done)
                      const LinearProgressIndicator()
                    else if (snapshot.hasError) ...[
                      const Text('No se pudo cargar el resumen de objetos.'),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Reintentar'),
                      ),
                    ] else ...[
                      Text(
                        summary!.total == null
                            ? 'Consulta los objetos registrados'
                            : '${summary.total} objetos registrados',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.uctBlue,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Revisa los hallazgos y su estado en la gestión de objetos.',
                      ),
                      if (summary.missingIds) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Hay registros sin identificador. No es posible cambiar su estado.',
                            style: TextStyle(color: Color(0xFF745500)),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openObjects,
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Gestionar objetos'),
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
                  'No hay objetos registrados.',
                  style: TextStyle(color: AppColors.subtitle),
                ),
              for (final item in summary.recent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.uctBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            LostObjectStatusBadge(
                              status: item.status,
                              isCompact: true,
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
