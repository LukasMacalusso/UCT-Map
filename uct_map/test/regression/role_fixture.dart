import 'package:flutter/material.dart';
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/entities/app_permission.dart';
import 'package:uct_map/presentation/screens/login/session_required_view.dart';

class ManualRolesApp extends StatelessWidget {
  const ManualRolesApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'UCT Map · Pruebas locales por rol',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF003865),
      useMaterial3: true,
    ),
    home: const _RoleHome(),
    onGenerateRoute: (settings) {
      const available = {
        AppRoutes.login,
        AppRoutes.professors,
        AppRoutes.teacherSchedule,
        AppRoutes.manageUsers,
        AppRoutes.manageObjects,
        AppRoutes.manageReports,
        AppRoutes.lostObjects,
        AppRoutes.createLostObject,
        AppRoutes.tickets,
        AppRoutes.createTicket,
        AppRoutes.ticketDetail,
      };
      if (available.contains(settings.name)) {
        return AppRoutes.onGenerateRoute(settings);
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Prueba local sin mapa')),
          body: const Center(
            child: Text(
              'La vista solicitada requiere el arranque normal de la app. El mapa Mapbox se prueba en Android, iOS o Web.',
            ),
          ),
        ),
      );
    },
  );
}

class _RoleHome extends StatelessWidget {
  const _RoleHome();

  @override
  Widget build(BuildContext context) {
    final session = ApiClientProvider.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Pruebas locales por rol')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Linux: login y apartados reales por rol. Esta entrada de pruebas no carga el mapa Mapbox.',
            ),
          ),
          Expanded(
            child: SessionRequiredView(
              embedded: true,
              builder: (context) {
                final user = session.currentUser!;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(user.email),
                    Text('Rol: ${user.role.toShortString()}'),
                    for (final entry in [
                      (
                        AppPermission.common,
                        'Directorio de profesores y reserva',
                        AppRoutes.professors,
                      ),
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
                      if (entry.$1.allows(user.role))
                        ListTile(
                          title: Text(entry.$2),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.pushNamed(context, entry.$3),
                        ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await session.signOut();
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sesión cerrada; no se pudo limpiar el almacenamiento.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
