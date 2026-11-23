import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GuestHomeContent extends StatelessWidget {
  const GuestHomeContent({super.key});

  Widget _feature(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.uctBlue, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: const Color(0xFF526174), height: 1.45),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: const Color(0xFFF6F7F9),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                shadowColor: AppColors.uctBlue.withValues(alpha: 0.14),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.explore_outlined,
                        size: 40,
                        color: AppColors.uctBlue,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Conoce tu campus\ncon UCT Map',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.uctBlue,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Una guía para ubicar edificios, salas y servicios de la universidad desde tu móvil.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Explora sin una cuenta',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.uctBlue,
                ),
              ),
              _feature(
                context,
                Icons.map_outlined,
                'Mapa y ubicaciones',
                'Consulta los espacios del campus y ubica edificios y servicios en el mapa.',
              ),
              _feature(
                context,
                Icons.search,
                'Búsqueda y filtros',
                'Encuentra edificios, salas y servicios. Elige un campus y filtra por edificio o categoría.',
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.account_circle_outlined,
                          size: 20,
                          color: AppColors.uctBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cuando inicies sesión',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.uctBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Desde el icono de perfil puedes acceder a tu cuenta para consultar el directorio docente y usar Reportes y Objetos. Las opciones de citas y agenda dependen de tu rol.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.uctBlue,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
