import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/managed_user.dart';
import '../../../domain/repositories/identity_repository.dart';
import '../login/session_required_view.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, this.repository});
  final IdentityRepository? repository;
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late final IdentityRepository _repository =
      widget.repository ?? IdentityRepositoryImpl();
  late Future<List<ManagedUser>> _users;
  bool _busy = false;
  static const _roles = [
    'Student',
    'Teacher',
    'ObjectsOfficer',
    'ComplaintsOfficer',
    'Admin',
  ];
  @override
  void initState() {
    super.initState();
    _users = _load();
  }

  Future<List<ManagedUser>> _load() async {
    final session = ApiClientProvider.session;
    await session.ready;
    if (!session.isAuthenticated ||
        !AppPermission.manageUsers.allows(session.currentUser?.role)) {
      throw StateError('Acceso denegado');
    }
    return _repository.getUsers();
  }

  void _reload() {
    setState(() => _users = _load());
  }

  Future<void> _change(ManagedUser user, {String? role}) async {
    if (_busy) return;
    final session = ApiClientProvider.session;
    final token = session.token;
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar cambio'),
        content: Text(
          role == null
              ? '${user.isSuspended ? 'Reactivar' : 'Suspender'} a ${user.email}?'
              : 'Asignar únicamente $role a ${user.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (!mounted ||
        approved != true ||
        token == null ||
        token != session.token ||
        !AppPermission.manageUsers.allows(session.currentUser?.role)) {
      return;
    }
    setState(() => _busy = true);
    try {
      if (role != null) {
        await _repository.replaceRole(user.id, role);
      } else {
        await _repository.setSuspended(user.id, !user.isSuspended);
      }
      if (!mounted || session.token != token) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cambio guardado. La cuenta afectada debe volver a iniciar sesión para actualizar su rol.',
          ),
        ),
      );
      _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el cambio.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => Scaffold(
      appBar: AppBar(
        title: const Text('Administración de usuarios'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<ManagedUser>>(
        future: _users,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton(
                onPressed: _reload,
                child: const Text('No se pudieron cargar usuarios. Reintentar'),
              ),
            );
          }
          final users = snapshot.data!;
          if (users.isEmpty) {
            return const Center(child: Text('No hay usuarios.'));
          }
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final own = user.id == ApiClientProvider.session.currentUser?.id;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(user.email),
                      Text(
                        '${user.role} · ${user.isSuspended ? 'Suspendido' : 'Activo'}',
                      ),
                      if (own)
                        const Text('Tu cuenta actual')
                      else
                        Wrap(
                          spacing: 12,
                          children: [
                            DropdownButton<String>(
                              value: _roles.contains(user.role)
                                  ? user.role
                                  : null,
                              hint: const Text('Asignar rol'),
                              items: _roles
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _busy
                                  ? null
                                  : (role) {
                                      if (role != null && role != user.role) {
                                        _change(user, role: role);
                                      }
                                    },
                            ),
                            TextButton(
                              onPressed: _busy ? null : () => _change(user),
                              child: Text(
                                user.isSuspended ? 'Reactivar' : 'Suspender',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
  );
}
