import '../../widgets/unsaved_form.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../data/models/campus_location_dto.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/campus.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/structure.dart';
import '../login/session_required_view.dart';
import 'campus_location_picker_screen.dart';

class AdminStructuresScreen extends StatelessWidget {
  const AdminStructuresScreen({super.key, required this.campus});
  final Campus campus;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => _Structures(
      key: ValueKey(ApiClientProvider.session.token),
      campus: campus,
    ),
  );
}

class _Structures extends StatefulWidget {
  const _Structures({super.key, required this.campus});
  final Campus campus;
  @override
  State<_Structures> createState() => _StructuresState();
}

class _StructuresState extends State<_Structures> {
  final _data = CampusRemoteDataSource();
  late final String? _token = ApiClientProvider.session.token;
  late Future<List<Structure>> _structures = _data.getStructures(
    widget.campus.id,
  );
  bool get _authorized =>
      mounted &&
      _token != null &&
      _token == ApiClientProvider.session.token &&
      ApiClientProvider.session.isAuthenticated &&
      AppPermission.manageUsers.allows(
        ApiClientProvider.session.currentUser?.role,
      );
  void _reload() {
    if (_authorized)
      setState(() => _structures = _data.getStructures(widget.campus.id));
  }

  Future<void> _edit([Structure? structure]) async {
    if (!_authorized) return;
    try {
      final categories = await _data.getCategories();
      if (!mounted || !_authorized) return;
      final result = await Navigator.push<_StructurePayload>(
        context,
        MaterialPageRoute(
          builder: (_) => _StructureEditor(
            campus: widget.campus,
            structure: structure,
            categories: categories,
            token: _token!,
          ),
        ),
      );
      if (result == null || !_authorized) return;
      if (structure == null) {
        await _data.createStructure(result.toJson(widget.campus.id));
      } else {
        await _data.updateStructure(
          structure.id,
          result.toJson(widget.campus.id),
        );
      }
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la estructura: $error')),
        );
    }
  }

  Future<void> _delete(Structure structure) async {
    if (!_authorized) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar estructura'),
        content: Text(
          '¿Eliminar “${structure.name}”? Esta acción no se puede deshacer.',
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
    try {
      await _data.deleteStructure(structure.id);
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException && error.statusCode == 404
                  ? 'La estructura ya no existe. Actualiza la lista.'
                  : 'No se pudo eliminar la estructura.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Estructuras · ${widget.campus.name}'),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Crear estructura',
          onPressed: () => _edit(),
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: FutureBuilder<List<Structure>>(
      future: _structures,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text(
                'No se pudieron cargar las estructuras. Reintentar',
              ),
            ),
          );
        final structures = snapshot.data ?? [];
        if (structures.isEmpty)
          return const Center(
            child: Text('Este campus todavía no tiene estructuras.'),
          );
        return ListView.builder(
          itemCount: structures.length,
          itemBuilder: (context, index) {
            final item = structures[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text(
                '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}',
              ),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () => _edit(item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: () => _delete(item),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              onTap: () => _edit(item),
            );
          },
        );
      },
    ),
  );
}

class _StructurePayload {
  const _StructurePayload(
    this.name,
    this.categoryId,
    this.latitude,
    this.longitude,
  );
  final String name;
  final String? categoryId;
  final double latitude;
  final double longitude;
  Map<String, Object?> toJson(String campusId) => {
    'campusId': campusId,
    'name': name,
    'categoryId': categoryId,
    'latitude': latitude,
    'longitude': longitude,
  };
}

class _StructureEditor extends StatefulWidget {
  const _StructureEditor({
    required this.campus,
    required this.structure,
    required this.categories,
    required this.token,
  });
  final Campus campus;
  final Structure? structure;
  final List<Category> categories;
  final String token;
  @override
  State<_StructureEditor> createState() => _StructureEditorState();
}

class _StructureEditorState extends State<_StructureEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.structure?.name ?? '');
  late final _latitude = TextEditingController(
    text: '${widget.structure?.latitude ?? widget.campus.latitude}',
  );
  late final _longitude = TextEditingController(
    text: '${widget.structure?.longitude ?? widget.campus.longitude}',
  );
  late String? _categoryId = widget.structure?.categoryId.isEmpty == true
      ? null
      : widget.structure?.categoryId;
  bool _busy = false;
  bool get _authorized =>
      ApiClientProvider.session.isAuthenticated &&
      ApiClientProvider.session.token == widget.token &&
      AppPermission.manageUsers.allows(
        ApiClientProvider.session.currentUser?.role,
      );
  @override
  void dispose() {
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final point = await Navigator.push<CampusCoordinateDto>(
      context,
      MaterialPageRoute(
        builder: (_) => CampusLocationPickerScreen(
          latitude: double.tryParse(_latitude.text) ?? widget.campus.latitude,
          longitude:
              double.tryParse(_longitude.text) ?? widget.campus.longitude,
          title: 'Ubicación de estructura',
        ),
      ),
    );
    if (point != null && mounted && _authorized) {
      _latitude.text = point.latitude.toStringAsFixed(6);
      _longitude.text = point.longitude.toStringAsFixed(6);
    }
  }

  void _save() {
    if (_busy || !_authorized || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    Navigator.pop(
      context,
      _StructurePayload(
        _name.text.trim(),
        _categoryId,
        double.parse(_latitude.text),
        double.parse(_longitude.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) {
      if (!_authorized)
        return const Scaffold(body: Center(child: Text('La sesión cambió.')));
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.structure == null ? 'Nueva estructura' : 'Editar estructura',
          ),
        ),
        body: UnsavedForm(
          formKey: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
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
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  ...widget.categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _categoryId = v),
              ),
              for (final pair in [
                ('Latitud', _latitude, 90.0),
                ('Longitud', _longitude, 180.0),
              ])
                TextFormField(
                  controller: pair.$2,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(labelText: pair.$1),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    return n == null || !n.isFinite || n.abs() > pair.$3
                        ? 'Coordenada inválida'
                        : null;
                  },
                ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _selectLocation,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Elegir ubicación en el mapa'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Guardando…' : 'Guardar'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
