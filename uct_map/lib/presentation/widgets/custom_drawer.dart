import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import 'uct_logo.dart';
import '../../core/network/api_client_provider.dart';
import '../../domain/entities/app_permission.dart';

class CustomDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onSelectTab;

  const CustomDrawer({super.key, required this.currentIndex, this.onSelectTab});

  void _navigateToTab(BuildContext context, int index) {
    Navigator.pop(context);
    if (onSelectTab != null) {
      onSelectTab!(index);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (route) => false,
        arguments: index,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text(
              'UCT Map',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: const Text('Universidad Católica de Temuco'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(4.0),
                child: UctLogo(height: 48, width: 48),
              ),
            ),
            decoration: BoxDecoration(color: theme.colorScheme.primary),
          ),
          for (final entry in [
            (
              AppPermission.teacherSchedule,
              'Mis horarios y citas',
              AppRoutes.teacherSchedule,
            ),
            (
              AppPermission.manageObjects,
              'Gestionar objetos perdidos',
              AppRoutes.manageObjects,
            ),
            (
              AppPermission.manageReports,
              'Gestionar incidentes',
              AppRoutes.manageReports,
            ),
            (
              AppPermission.manageUsers,
              'Administrar usuarios',
              AppRoutes.manageUsers,
            ),
          ])
            if (ApiClientProvider.session.isAuthenticated &&
                entry.$1.allows(ApiClientProvider.session.currentUser?.role))
              ListTile(
                leading: const Icon(Icons.manage_accounts),
                title: Text(entry.$2),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, entry.$3);
                },
              ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Inicio y Accesos Rápidos'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(context, AppRoutes.home);
              if (result is int && context.mounted) {
                if (onSelectTab != null) {
                  onSelectTab!(result);
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.initial,
                    (route) => false,
                    arguments: result,
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Mapa del Campus'),
            selected: currentIndex == 0,
            onTap: () => _navigateToTab(context, 0),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Búsqueda de Espacios'),
            selected: currentIndex == 1,
            onTap: () => _navigateToTab(context, 1),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: const Text('Objetos Perdidos'),
            selected: currentIndex == 2,
            onTap: () => _navigateToTab(context, 2),
          ),
          ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: const Text('Reportes de Incidencias'),
            selected: currentIndex == 3,
            onTap: () => _navigateToTab(context, 3),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Mi Perfil'),
            selected: currentIndex == 4,
            onTap: () => _navigateToTab(context, 4),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Servicios y Accesos Directos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Directorio de Profesores'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.professors,
              );
              if (result == 0 && context.mounted) {
                _navigateToTab(context, 0);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark_outline),
            title: const Text('Lugares Guardados'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.savedPlaces,
              );
              if (result == 0 && context.mounted) {
                _navigateToTab(context, 0);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Mis Reportes'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.myReports,
              );
              if (result == 3 && context.mounted) {
                _navigateToTab(context, 3);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.find_in_page_outlined),
            title: const Text('Objetos Reportados'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.myLostItems,
              );
              if (result == 2 && context.mounted) {
                _navigateToTab(context, 2);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.profileSettings);
            },
          ),
        ],
      ),
    );
  }
}
