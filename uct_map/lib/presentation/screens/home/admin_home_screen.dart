import 'package:flutter/material.dart';

import '../../../application/dashboard/management_dashboard.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/repositories/identity_repository.dart';
import '../login/session_required_view.dart';
import 'management_home_layout.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key, this.repository, this.active = true});
  final IdentityRepository? repository;
  final bool active;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    embedded: true,
    builder: (_) => _AdminHome(
      key: ValueKey(ApiClientProvider.session.token),
      repository: repository ?? IdentityRepositoryImpl(),
      active: active,
    ),
  );
}

class _AdminHome extends StatefulWidget {
  const _AdminHome({super.key, required this.repository, required this.active});
  final IdentityRepository repository;
  final bool active;
  @override
  State<_AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<_AdminHome> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late Future<AdminDashboardSummary> _summary = _load();
  void _checkSession() {
    if (!mounted ||
        !_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageUsers.allows(_session.currentUser?.role)) {
      throw StateError('La sesión cambió.');
    }
  }

  Future<AdminDashboardSummary> _load() =>
      loadAdminDashboard(widget.repository, _checkSession);
  void _reload() => setState(() {
    _summary = _load();
  });
  @override
  void didUpdateWidget(covariant _AdminHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _reload();
  }

  Future<void> _openUsers() async {
    if (!_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageUsers.allows(_session.currentUser?.role)) {
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.manageUsers);
    if (mounted && _token == _session.token) _reload();
  }

  Future<void> _openCampus() async {
    if (!_session.isAuthenticated ||
        _token != _session.token ||
        !AppPermission.manageUsers.allows(_session.currentUser?.role)) {
      return;
    }
    await Navigator.pushNamed(context, AppRoutes.manageCampus);
    if (mounted && _token == _session.token) _reload();
  }

  @override
  Widget build(BuildContext context) => ManagementHomeLayout(
    icon: Icons.manage_accounts_outlined,
    child: Column(
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
                  'Administración de usuarios',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.uctBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<AdminDashboardSummary>(
                  future: _summary,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const LinearProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No se pudo cargar el resumen de usuarios.',
                          ),
                          TextButton(
                            onPressed: _reload,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      );
                    }
                    final summary = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.total} cuentas registradas',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.uctBlue,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Revisa los roles y el acceso de las cuentas del campus.',
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 32,
                          runSpacing: 12,
                          children: [
                            Text(
                              'Activas: ${summary.active}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Suspendidas: ${summary.suspended}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.subtitle),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openUsers,
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Gestionar usuarios'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openCampus,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Administrar campus'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Permisos de administración',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppColors.uctBlue, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        const Text(
          'Los cambios de rol y suspensión se realizan en la gestión de usuarios. Las acciones de objetos e incidentes corresponden a sus encargados.',
          style: TextStyle(color: AppColors.subtitle, height: 1.45),
        ),
      ],
    ),
  );
}
