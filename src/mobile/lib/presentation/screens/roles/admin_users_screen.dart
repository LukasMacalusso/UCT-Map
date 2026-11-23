import '../../../application/directory/filter_users.dart';
import '../../../core/theme/app_colors.dart';
import 'admin_user_detail_screen.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../data/repositories/identity_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/managed_user.dart';
import '../../../domain/repositories/identity_repository.dart';
import '../login/session_required_view.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key, this.repository});
  final IdentityRepository? repository;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => _AdminUsers(
      key: ValueKey(ApiClientProvider.session.token),
      repository: repository,
    ),
  );
}

class _AdminUsers extends StatefulWidget {
  const _AdminUsers({super.key, this.repository});
  final IdentityRepository? repository;
  @override
  State<_AdminUsers> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<_AdminUsers> {
  late final IdentityRepository _repository =
      widget.repository ?? IdentityRepositoryImpl();
  late Future<List<ManagedUser>> _users;
  late final _token = ApiClientProvider.session.token;
  bool _busy = false;
  String _query = '';
  String? _roleFilter;
  bool? _suspendedFilter;
  int _page = 0;
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
    final users = await _repository.getUsers();
    if (session.token != _token ||
        !session.isAuthenticated ||
        !AppPermission.manageUsers.allows(session.currentUser?.role)) {
      throw StateError('La sesión cambió.');
    }
    return users;
  }

  void _reload() {
    setState(() {
      _users = _load();
    });
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

  Widget _filters() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar usuarios',
            hintText: 'Nombre o correo',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() {
            _query = value;
            _page = 0;
          }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String?>(
          initialValue: _roleFilter,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Rol'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Todos los roles'),
            ),
            ..._roles.map((r) => DropdownMenuItem(value: r, child: Text(r))),
          ],
          onChanged: (value) => setState(() {
            _roleFilter = value;
            _page = 0;
          }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<bool?>(
          initialValue: _suspendedFilter,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Estado de la cuenta'),
          items: const [
            DropdownMenuItem<bool?>(value: null, child: Text('Todas')),
            DropdownMenuItem(value: false, child: Text('Activas')),
            DropdownMenuItem(value: true, child: Text('Suspendidas')),
          ],
          onChanged: (value) => setState(() {
            _suspendedFilter = value;
            _page = 0;
          }),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administración de usuarios'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
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
        final filtered = filterUsers(
          users,
          query: _query,
          role: _roleFilter,
          suspended: _suspendedFilter,
        );
        final pages = (filtered.length / 20).ceil();
        final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
        final visible = filtered.skip(page * 20).take(20).toList();
        return ListView.builder(
          itemCount: visible.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return _filters();
            if (index == visible.length + 1) {
              if (filtered.isEmpty)
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay cuentas para estos filtros.'),
                );
              if (pages < 2) return const SizedBox(height: 16);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Página anterior',
                    onPressed: page == 0
                        ? null
                        : () => setState(() => _page = page - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${page + 1} de $pages'),
                  IconButton(
                    tooltip: 'Página siguiente',
                    onPressed: page + 1 >= pages
                        ? null
                        : () => setState(() => _page = page + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              );
            }
            final user = visible[index - 1];
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
                    TextButton.icon(
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Ver perfil'),
                      onPressed: _busy
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => AdminUserDetailScreen(
                                    userId: user.id,
                                    repository: _repository,
                                  ),
                                ),
                              );
                              if (mounted &&
                                  ApiClientProvider.session.token == _token)
                                _reload();
                            },
                    ),
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
  );
}
