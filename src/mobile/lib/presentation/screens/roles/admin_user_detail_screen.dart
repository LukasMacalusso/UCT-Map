import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/managed_user.dart';
import '../../../domain/repositories/identity_repository.dart';
import '../login/session_required_view.dart';

class AdminUserDetailScreen extends StatelessWidget {
  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    this.repository,
  });
  final String userId;
  final IdentityRepository? repository;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => _Detail(
      key: ValueKey('${ApiClientProvider.session.token}:$userId'),
      userId: userId,
      repository: repository ?? IdentityRepositoryImpl(),
    ),
  );
}

class _Detail extends StatefulWidget {
  const _Detail({super.key, required this.userId, required this.repository});
  final String userId;
  final IdentityRepository repository;
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late Future<ManagedUser> _data = _load();
  Future<ManagedUser> _load() async {
    if (_token == null ||
        _session.token != _token ||
        !AppPermission.manageUsers.allows(_session.currentUser?.role))
      throw const ForbiddenException();
    final user = await widget.repository.getUserById(widget.userId);
    if (_session.token != _token ||
        !AppPermission.manageUsers.allows(_session.currentUser?.role))
      throw const ForbiddenException();
    if (user.id != widget.userId)
      throw const FormatException('El usuario no corresponde a la consulta.');
    return user;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Información de la cuenta'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Actualizar cuenta',
          onPressed: () => setState(() => _data = _load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<ManagedUser>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  snapshot.error is ApiException &&
                          (snapshot.error as ApiException).statusCode == 404
                      ? 'La cuenta ya no está disponible.'
                      : 'No se pudo cargar la cuenta.',
                ),
                TextButton(
                  onPressed: () => setState(() => _data = _load()),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        final user = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.uctBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(user.email),
                const SizedBox(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Rol'),
                  subtitle: Text(user.role),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    user.isSuspended
                        ? Icons.lock_outline
                        : Icons.verified_user_outlined,
                  ),
                  title: const Text('Estado de la cuenta'),
                  subtitle: Text(user.isSuspended ? 'Suspendida' : 'Activa'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
