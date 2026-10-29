import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../application/session/session_controller.dart';
import '../../../domain/entities/user_role.dart';
import '../login/session_required_view.dart';
import 'saved_places_screen.dart';
import 'my_reports_screen.dart';
import 'my_lost_items_screen.dart';
import 'profile_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final SessionController? session;
  final Function(int)? onNavigateToTab;
  final Future<void> Function()? onLogout;
  final int savedPlacesCount;
  final int reportsCount;
  final int notificationsCount;

  const ProfileScreen({
    super.key,
    this.session,
    this.onNavigateToTab,
    this.onLogout,
    this.savedPlacesCount = 4,
    this.reportsCount = 3,
    this.notificationsCount = 1,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Avatar seleccionado (índice para simulación de cambio de foto)
  int _avatarIndex = 0;

  final List<IconData> _avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.school,
    Icons.sentiment_very_satisfied,
  ];

  void _openChangePhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cambiar Foto de Perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.uctBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.uctBlue,
                    ),
                  ),
                  title: const Text('Tomar Foto'),
                  subtitle: const Text('Abrir cámara del dispositivo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _avatarIndex = (_avatarIndex + 1) % _avatarIcons.length;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto actualizada desde la cámara'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.uctGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.uctBlue,
                    ),
                  ),
                  title: const Text('Elegir de la Galería'),
                  subtitle: const Text('Seleccionar una imagen de tu galería'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _avatarIndex = (_avatarIndex + 2) % _avatarIcons.length;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto actualizada desde la galería'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Eliminar Foto'),
                  subtitle: const Text('Restablecer al avatar por defecto'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _avatarIndex = 0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto de perfil restablecida'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    final userName = (widget.session?.isAuthenticated == true) ? (user?.name ?? user?.email ?? 'Usuario') : 'Invitado';
    final userEmail = (widget.session?.isAuthenticated == true) ? (user?.email ?? '') : 'Modo invitado (sin cuenta)';
    final userRole = user?.role;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),

          // 1. Imagen del usuario con lápiz para poder cambiarla (según Figma)
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
                      _avatarIcons[_avatarIndex],
                      size: 56,
                      color: AppColors.uctBlue,
                    ),
                  ),
                ),
                // Botón de lápiz superpuesto para cambiar la imagen
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _openChangePhotoSheet,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.uctGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 17,
                        color: AppColors.uctBlue,
                      ),
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
          // 1) Mis favoritos o guardados
          _buildMenuButton(
            title: 'Mis favoritos o guardados',
            subtitle: 'Lugares y espacios guardados',
            icon: Icons.bookmark_rounded,
            iconColor: AppColors.uctBlue,
            badgeText: widget.savedPlacesCount > 0
                ? '${widget.savedPlacesCount}'
                : null,
            badgeColor: AppColors.uctBlue.withValues(alpha: 0.08),
            badgeTextColor: AppColors.uctBlue,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SavedPlacesScreen(
                      onNavigateToTab: widget.onNavigateToTab,
                  ),
                ),
              );
              if (result is int && widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(result);
              }
            },
          ),

          const SizedBox(height: 12),

          // 2) Mis reportes
          _buildMenuButton(
            title: 'Mis reportes',
            subtitle: 'Seguimiento de incidencias',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF0284C7),
            badgeText: widget.reportsCount > 0
                ? '${widget.reportsCount}'
                : null,
            badgeColor: const Color(0xFFE0F2FE),
            badgeTextColor: const Color(0xFF0369A1),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionRequiredView(
                    builder: (_) => MyReportsScreen(
                      onNavigateToTab: widget.onNavigateToTab,
                    ),
                  ),
                ),
              );
              if (result is int && widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(result);
              }
            },
          ),

          const SizedBox(height: 12),

          // 3) Objetos reportados (solo muestra la cantidad numérica de notificaciones)
          _buildMenuButton(
            title: 'Objetos reportados',
            subtitle: 'Seguimiento y notificaciones',
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF16A34A),
            badgeText: widget.notificationsCount > 0
                ? '${widget.notificationsCount}'
                : null,
            badgeColor: const Color(0xFFDCFCE7),
            badgeTextColor: const Color(0xFF15803D),
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionRequiredView(
                    builder: (_) => MyLostItemsScreen(
                      onNavigateToTab: widget.onNavigateToTab,
                    ),
                  ),
                ),
              );
              if (result is int && widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(result);
              }
            },
          ),

          const SizedBox(height: 12),

          // 4) Configuración
          _buildMenuButton(
            title: 'Configuración',
            subtitle: 'Preferencias de la aplicación',
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
