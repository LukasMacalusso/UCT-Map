import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// Placeholder de sección protegida: reemplaza el contenido real hasta login.
class AuthRequiredView extends StatelessWidget {
  final VoidCallback onLogin;

  const AuthRequiredView({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outlined, color: AppColors.uctBlue, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Para acceder a este contenido inicia sesión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('authGateLoginButton'),
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.uctBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
