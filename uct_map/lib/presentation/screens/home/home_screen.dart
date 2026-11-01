import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../domain/entities/app_permission.dart';
import '../login/session_required_view.dart';
import 'student_home_screen.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_drawer.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  void _goToTab(BuildContext context, int tabIndex) {
    if (onNavigateToTab != null) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, tabIndex);
      }
      onNavigateToTab!(tabIndex);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, tabIndex);
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.initial,
        arguments: tabIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AppPermission.bookConsultation.allows(
      ApiClientProvider.session.currentUser?.role,
    )) {
      return SessionRequiredView(
        permission: AppPermission.bookConsultation,
        builder: (_) => const StudentHomeScreen(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inicio - UCT Map',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      drawer: CustomDrawer(
        currentIndex: -1,
        onSelectTab: (index) => _goToTab(context, index),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de bienvenida
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.uctBlue, Color(0xFF025A9B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Bienvenido a UCT Map!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Encuentra tus salas, edificios, oficinas de profesores y más.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Accesos Rápidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            // Grid de accesos directos
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildQuickActionCard(
                  context,
                  icon: Icons.map_outlined,
                  title: 'Ver Mapa',
                  subtitle: 'Explorar campus',
                  color: Colors.blue,
                  onTap: () => _goToTab(context, 0),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.search,
                  title: 'Buscar Salas',
                  subtitle: 'Aulas y laboratorios',
                  color: Colors.orange,
                  onTap: () => _goToTab(context, 1),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.find_in_page_outlined,
                  title: 'Objetos Perdidos',
                  subtitle: 'Consultar o reportar',
                  color: Colors.purple,
                  onTap: () => _goToTab(context, 2),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.report_problem_outlined,
                  title: 'Reportes',
                  subtitle: 'Reportar incidencias',
                  color: Colors.redAccent,
                  onTap: () => _goToTab(context, 3),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.school_outlined,
                  title: 'Profesores',
                  subtitle: 'Directorio y oficinas',
                  color: Colors.green,
                  onTap: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.professors,
                    );
                    if (res == 0 && context.mounted) {
                      _goToTab(context, 0);
                    }
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.bookmark_outline,
                  title: 'Guardados',
                  subtitle: 'Lugares favoritos',
                  color: AppColors.uctGold,
                  onTap: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.savedPlaces,
                    );
                    if (res == 0 && context.mounted) {
                      _goToTab(context, 0);
                    }
                  },
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.person_outline,
                  title: 'Mi Perfil',
                  subtitle: 'Datos de usuario',
                  color: Colors.teal,
                  onTap: () => _goToTab(context, 4),
                ),
                _buildQuickActionCard(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Configuración',
                  subtitle: 'Preferencias de app',
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.profileSettings);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.fieldBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                radius: 24,
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.subtitle, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
