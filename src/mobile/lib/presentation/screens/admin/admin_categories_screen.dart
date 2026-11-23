import '../../widgets/unsaved_form.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/category.dart';
import '../login/session_required_view.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => _Categories(key: ValueKey(ApiClientProvider.session.token)),
  );
}

class _Categories extends StatefulWidget {
  const _Categories({super.key});
  @override
  State<_Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<_Categories> {
  final _data = CampusRemoteDataSource();
  late final String? _token = ApiClientProvider.session.token;
  late Future<List<Category>> _categories = _load();
  bool _busy = false;
  bool get _authorized =>
      mounted &&
      _token != null &&
      _token == ApiClientProvider.session.token &&
      ApiClientProvider.session.isAuthenticated &&
      AppPermission.manageUsers.allows(
        ApiClientProvider.session.currentUser?.role,
      );
  Future<List<Category>> _load() async =>
      (await _data.getCategories())..sort((a, b) => a.order.compareTo(b.order));
  void _reload() {
    if (_authorized) setState(() => _categories = _load());
  }

  Future<void> _edit([Category? category]) async {
    if (!_authorized || _busy) return;
    final payload = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
    );
    if (payload == null || !_authorized) return;
    setState(() => _busy = true);
    try {
      if (category == null) {
        await _data.createCategory({
          ...payload,
          'order': (await _load()).length,
        });
      } else {
        await _data.updateCategory(category.id, {
          ...payload,
          'order': category.order,
        });
      }
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la categoría: $error')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reorder(
    List<Category> categories,
    int oldIndex,
    int newIndex,
  ) async {
    if (!_authorized || _busy) return;
    final changed = List<Category>.from(categories);
    final moved = changed.removeAt(oldIndex);
    changed.insert(newIndex, moved);
    setState(() {
      _busy = true;
      _categories = Future.value(changed);
    });
    try {
      await _data.reorderCategories([
        for (var i = 0; i < changed.length; i++)
          {'id': changed[i].id, 'order': i},
      ]);
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el nuevo orden: $error')),
        );
        _reload();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Category category) async {
    if (!_authorized || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Eliminar “${category.name}”? Los edificios, salas y estructuras asociados quedarán sin categoría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !_authorized) return;
    setState(() => _busy = true);
    try {
      await _data.deleteCategory(category.id);
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException && error.statusCode == 409
                  ? 'La categoría no se puede eliminar por sus dependencias.'
                  : 'No se pudo eliminar la categoría.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administrar categorías'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Crear categoría',
          onPressed: _busy ? null : () => _edit(),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: FutureBuilder<List<Category>>(
      future: _categories,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text(
                'No se pudieron cargar las categorías. Reintentar',
              ),
            ),
          );
        final categories = snapshot.data ?? [];
        if (categories.isEmpty)
          return const Center(child: Text('No hay categorías configuradas.'));
        return ReorderableListView.builder(
          itemCount: categories.length,
          onReorderItem: _busy
              ? (_, _) {}
              : (oldIndex, newIndex) =>
                    _reorder(categories, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final item = categories[index];
            return ListTile(
              key: ValueKey(item.id),
              leading: const Icon(Icons.drag_handle),
              title: Text(item.name),
              subtitle: Text(
                item.description.isEmpty
                    ? item.icon
                    : '${item.icon} · ${item.description}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: _busy ? null : () => _edit(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: _busy ? null : () => _delete(item),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.category});
  final Category? category;
  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late final _icon = TextEditingController(
    text: widget.category?.icon ?? 'place',
  );
  late final _description = TextEditingController(
    text: widget.category?.description ?? '',
  );
  @override
  void dispose() {
    _name.dispose();
    _icon.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.category == null ? 'Nueva categoría' : 'Editar categoría',
    ),
    content: UnsavedForm(
      formKey: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Campo obligatorio'
                  : v.trim().length > 100
                  ? 'Máximo 100 caracteres'
                  : null,
            ),
            TextFormField(
              controller: _icon,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Icono (nombre o referencia)',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Campo obligatorio'
                  : v.trim().length > 100
                  ? 'Máximo 100 caracteres'
                  : null,
            ),
            TextFormField(
              controller: _description,
              maxLength: 250,
              decoration: const InputDecoration(
                labelText: 'Descripción opcional',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.maybePop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(context, {
            'name': _name.text.trim(),
            'icon': _icon.text.trim(),
            'description': _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
          });
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
