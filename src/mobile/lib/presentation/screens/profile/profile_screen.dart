import '../../../application/contributions/user_reports.dart';
import '../../../application/contributions/user_objects.dart';
import '../../../domain/repositories/reports_repository.dart';
import '../../../domain/repositories/lost_objects_repository.dart';
import '../../../data/repositories/reports_repository_impl.dart';
import '../../../data/repositories/lost_objects_repository_impl.dart';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../application/session/session_controller.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/entities/managed_user.dart';
import '../../../domain/repositories/identity_repository.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import '../login/session_required_view.dart';
import 'my_reports_screen.dart';
import 'my_lost_items_screen.dart';
import 'profile_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final SessionController? session;
  final IdentityRepository? repository;
  final ReportsRepository? reportsRepository;
  final LostObjectsRepository? objectsRepository;
  final bool active;
  final Function(int)? onNavigateToTab;
  final Future<void> Function()? onLogout;
  final int savedPlacesCount;
  final int reportsCount;
  final int notificationsCount;

  const ProfileScreen({
    super.key,
    this.session,
    this.repository,
    this.reportsRepository,
    this.objectsRepository,
    this.active = true,
    this.onNavigateToTab,
    this.onLogout,
    this.savedPlacesCount = 0,
    this.reportsCount = 0,
    this.notificationsCount = 0,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ManagedUser? _profile;
  int? _reportCount;
  int? _objectCount;
  bool _countsFailed = false;
  bool _loadingProfile = false;
  bool _profileFailed = false;
  int _profileRequest = 0;

  @override
  void initState() {
    super.initState();
    widget.session?.addListener(_sessionChanged);
    if (widget.active) _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session?.removeListener(_sessionChanged);
      widget.session?.addListener(_sessionChanged);
      _sessionChanged();
    } else if (widget.active && !oldWidget.active) {
      _loadProfile();
    }
  }

  void _sessionChanged() {
    if (!mounted) return;
    _profileRequest++;
    setState(() {
      _profile = null;
      _reportCount = null;
      _objectCount = null;
      _loadingProfile = false;
      _profileFailed = false;
    });
    if (widget.active && widget.session?.isAuthenticated == true) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    widget.session?.removeListener(_sessionChanged);
    _profileRequest++;
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final request = ++_profileRequest;
    final session = widget.session;
    _profile = null;
    if (session == null) return;
    await session.ready;
    if (!mounted || request != _profileRequest || !widget.active) return;
    final token = session.token;
    final id = session.currentUser?.id;
    if (token == null || id == null) return;
    setState(() {
      _loadingProfile = true;
      _profileFailed = false;
      _reportCount = null;
      _objectCount = null;
    });
    _loadCounts(request);
    try {
      final profile = await (widget.repository ?? IdentityRepositoryImpl())
          .getUserById(id);
      if (!mounted || request != _profileRequest || session.token != token) {
        return;
      }
      if (profile.id != id || profile.email != session.currentUser?.email) {
        throw const FormatException('El perfil no corresponde a tu sesión.');
      }
      setState(() {
        _profile = profile;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted || request != _profileRequest || session.token != token) {
        return;
      }
      setState(() {
        _profileFailed = true;
        _loadingProfile = false;
      });
    }
  }

  Future<void> _loadCounts(int request) async {
    final session = widget.session;
    if (session == null || !session.isAuthenticated) return;
    final token = session.token;
    bool current() =>
        mounted &&
        widget.active &&
        request == _profileRequest &&
        session.token == token;
    final reports = widget.reportsRepository ?? ReportsRepositoryImpl();
    try {
      final tickets = await loadUserReports(reports, session);
      if (!current()) return;
      final objects = await loadUserObjects(
        reports,
        widget.objectsRepository ?? LostObjectsRepositoryImpl(),
        session,
        loadedReports: tickets,
      );
      if (!current()) return;
      setState(() {
        _reportCount = tickets.where((r) => r.complaintDetails != null).length;
        _objectCount = objects.items.length;
        _countsFailed = false;
      });
    } catch (_) {
      if (current())
        setState(() {
          _reportCount = null;
          _objectCount = null;
          _countsFailed = true;
        });
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que deseas cerrar sesión? Deberás ingresar nuevamente con tu correo institucional @uct.cl.',
            style: TextStyle(fontSize: 14, color: AppColors.subtitle),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.subtitle),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                if (widget.onLogout != null) {
                  await widget.onLogout!();
                  return;
                }
                try {
                  if (widget.session != null) {
                    await widget.session!.signOut();
                  }
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sesión cerrada, pero no se pudo borrar el token local.',
                      ),
                    ),
                  );
                  return;
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sesión cerrada correctamente'),
                    backgroundColor: AppColors.uctBlue,
                  ),
                );
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.estudiante:
        return 'Estudiante';
      case UserRole.profesor:
        return 'Docente / Profesor';
      case UserRole.administrador:
        return 'Administrador';
      case UserRole.funcionarioObjetos:
        return 'Funcionario Custodia';
      case UserRole.funcionarioQuejas:
        return 'Funcionario Incidencias';
      case UserRole.invitado:
        return 'Invitado';
      case UserRole.desconocido:
        return 'Sin rol asignado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session?.currentUser;
    final userName = (widget.session?.isAuthenticated == true)
        ? (_profile?.name.trim().isNotEmpty == true
              ? _profile!.name
              : (user?.name ?? user?.email ?? 'Usuario'))
        : 'Invitado';
    final userEmail = (widget.session?.isAuthenticated == true)
        ? (_profile?.email ?? user?.email ?? '')
        : 'Modo invitado (sin cuenta)';
    final userRole = user?.role;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // Avatar sin edición hasta disponer de una fuente de imágenes real.
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.uctGold, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.uctBlue.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFF1F5F9),
                    child: Icon(
                      Icons.person,
                      size: 56,
                      color: AppColors.uctBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Nombre del usuario (correo si el backend no lo envía)
          Text(
            userName,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            userEmail,
            style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
          ),

          if (_loadingProfile)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(semanticsLabel: 'Cargando perfil'),
            ),
          if (_profileFailed)
            TextButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('No se pudo cargar el perfil. Reintentar'),
            ),
          const SizedBox(height: 12),

          // Rol del usuario según sesión; oculto si no hay rol asignado.
          if (userRole != null && userRole != UserRole.desconocido)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.uctBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.uctBlue.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 16,
                    color: AppColors.uctBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user!.roles.map(_getRoleLabel).join(' · '),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.uctBlue,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // 3. Los 5 botones principales según el diseño Figma:
          if (widget.session?.isAuthenticated == true &&
              userRole == UserRole.estudiante) ...[
            _buildMenuButton(
              title: 'Mis citas',
              subtitle: 'Consultar tus próximas consultas',
              icon: Icons.event_note,
              iconColor: AppColors.uctBlue,
              onTap: () => Navigator.pushNamed(context, '/my-meetings'),
            ),
            const SizedBox(height: 12),
          ],
          if (_countsFailed)
            TextButton(
              onPressed: () => _loadCounts(_profileRequest),
              child: const Text(
                'No se pudieron cargar los contadores. Reintentar',
              ),
            ),
          // 2) Mis reportes
          _buildMenuButton(
            title: 'Mis reportes',
            subtitle: 'Seguimiento de incidencias',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF0284C7),
            badgeText: _reportCount == null ? null : '$_reportCount',
            badgeColor: const Color(0xFFE0F2FE),
            badgeTextColor: const Color(0xFF0369A1),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionRequiredView(
                    builder: (_) => MyReportsScreen(
                      onNavigateToTab: widget.onNavigateToTab,
                      repository: widget.reportsRepository,
                    ),
                  ),
                ),
              );
              if (mounted && widget.active) _loadProfile();
              if (result is int && widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(result);
              }
            },
          ),

          const SizedBox(height: 12),

          // 3) Objetos reportados (solo muestra la cantidad numérica de notificaciones)
          _buildMenuButton(
            title: 'Objetos reportados',
            subtitle: 'Objetos vinculados a tus reportes',
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF16A34A),
            badgeText: _objectCount == null ? null : '$_objectCount',
            badgeColor: const Color(0xFFDCFCE7),
            badgeTextColor: const Color(0xFF15803D),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionRequiredView(
                    builder: (_) => MyLostItemsScreen(
                      onNavigateToTab: widget.onNavigateToTab,
                      reportsRepository: widget.reportsRepository,
                      objectsRepository: widget.objectsRepository,
                    ),
                  ),
                ),
              );
              if (mounted && widget.active) _loadProfile();
              if (result is int && widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(result);
              }
            },
          ),

          const SizedBox(height: 12),

          // 4) Configuración
          _buildMenuButton(
            title: 'Configuración',
            subtitle: 'Información de cuenta y acceso',
            icon: Icons.settings_outlined,
            iconColor: const Color(0xFF475569),
            badgeText: null,
            badgeColor: null,
            badgeTextColor: null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileSettingsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // 5) Cerrar sesión
          _buildMenuButton(
            title: 'Cerrar sesión',
            subtitle: 'Finalizar la sesión actual',
            icon: Icons.logout_rounded,
            iconColor: Colors.red.shade700,
            badgeText: null,
            badgeColor: null,
            badgeTextColor: null,
            isDestructive: true,
            onTap: _confirmLogout,
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.shade50.withValues(alpha: 0.6)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDestructive
                  ? Colors.red.shade200
                  : AppColors.fieldBorder,
              width: 1,
            ),
            boxShadow: isDestructive
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red.shade100
                      : iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDestructive
                            ? Colors.red.shade800
                            : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDestructive
                            ? Colors.red.shade400
                            : AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null &&
                  badgeColor != null &&
                  badgeTextColor != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.chevron_right,
                color: isDestructive ? Colors.red.shade300 : AppColors.hint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
