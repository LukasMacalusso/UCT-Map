import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../login/session_required_view.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    builder: (_) => Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: ApiClientProvider.session,
        builder: (context, _) {
          final user = ApiClientProvider.session.currentUser;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Tu cuenta UCT Map',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.uctBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Acceso y sesión',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión con tu cuenta del proyecto. Al cerrar sesión desde Perfil se elimina el acceso guardado en este dispositivo. Si la sesión vence, vuelve a identificarte.',
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Ubicación',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'El mapa solicita el permiso del dispositivo cuando usas tu ubicación. Puedes administrarlo desde los ajustes del sistema o del navegador.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
