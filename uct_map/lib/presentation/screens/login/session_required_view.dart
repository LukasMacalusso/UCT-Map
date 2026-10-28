import 'package:flutter/material.dart';

import '../../../application/session/session_controller.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'access_denied_view.dart';
import 'auth_required_view.dart';

// Las rutas secundarias comparten la misma sesión que la navegación principal.
class SessionRequiredView extends StatefulWidget {
  const SessionRequiredView({
    super.key,
    required this.builder,
    this.permission = AppPermission.common,
    this.embedded = false,
  });

  final WidgetBuilder builder;
  final AppPermission permission;
  final bool embedded;

  @override
  State<SessionRequiredView> createState() => _SessionRequiredViewState();
}

class _SessionRequiredViewState extends State<SessionRequiredView> {
  late final SessionController _session = ApiClientProvider.session;
  late final Future<void> _ready = _session.ready;
  bool _busy = false;

  Future<void> _login(BuildContext context) async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await Navigator.pushNamed(context, '/login');
      if (!context.mounted || result is! Map || result['ok'] != true) return;
      await _session.signInReal(
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
    } finally {
      _busy = false;
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;
    _busy = true;
    try {
      await _session.signOut();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sesión cerrada, pero no se pudo borrar el token local.',
            ),
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  Widget _placeholder(Widget child) => widget.embedded
      ? child
      : Scaffold(
          appBar: AppBar(title: const Text('Acceso protegido')),
          body: child,
        );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _placeholder(const Center(child: CircularProgressIndicator()));
        }
        return ListenableBuilder(
          listenable: _session,
          builder: (context, _) {
            if (!_session.isAuthenticated) {
              return _placeholder(
                AuthRequiredView(onLogin: () => _login(context)),
              );
            }
            if (!widget.permission.allows(_session.currentUser?.role)) {
              return _placeholder(AccessDeniedView(onSignOut: _signOut));
            }
            // El contenido de una cuenta no se reutiliza al cambiar de usuario.
            return KeyedSubtree(
              key: ValueKey(_session.currentUser!.id),
              child: widget.builder(context),
            );
          },
        );
      },
    );
  }
}
