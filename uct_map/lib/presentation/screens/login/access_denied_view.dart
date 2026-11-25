import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AccessDeniedView extends StatelessWidget {
  const AccessDeniedView({super.key, required this.onSignOut})
    : message = 'Tu rol no tiene acceso a esta sección.';

  const AccessDeniedView.resource({super.key})
    : message = 'No tienes permiso para acceder a estos datos.',
      onSignOut = null;

  final String message;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_accounts_outlined,
              size: 56,
              color: AppColors.uctBlue,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (onSignOut != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onSignOut,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
