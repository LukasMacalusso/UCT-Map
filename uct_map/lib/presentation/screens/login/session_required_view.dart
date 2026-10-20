import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_required_view.dart';

// Las rutas secundarias comparten la misma sesión que la navegación principal.
class SessionRequiredView extends StatelessWidget {
  const SessionRequiredView({super.key, required this.builder});

  final WidgetBuilder builder;

  Future<void> _login(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/login');
    if (!context.mounted || result is! Map || result['ok'] != true) return;
    try {
      await ApiClientProvider.session.signInReal(
        AuthLoginResult(
          userId: result['userId'] as String,
          email: result['email'] as String,
          token: result['token'] as String,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar sesión.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sesión compartida: la misma que usa la navegación principal.
    final session = ApiClientProvider.session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => session.isAuthenticated
          ? builder(context)
          : Scaffold(
              appBar: AppBar(title: const Text('Acceso protegido')),
              body: AuthRequiredView(onLogin: () => _login(context)),
            ),
    );
  }
}
