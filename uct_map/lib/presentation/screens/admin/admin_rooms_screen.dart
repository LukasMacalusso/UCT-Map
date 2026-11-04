import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/room.dart';
import '../login/session_required_view.dart';

class AdminRoomsScreen extends StatelessWidget {
  const AdminRoomsScreen({
    super.key,
    required this.buildingId,
    required this.buildingName,
    required this.floorsCount,
  });
  final String buildingId;
  final String buildingName;
  final int floorsCount;

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => _Rooms(
      key: ValueKey(ApiClientProvider.session.token),
      buildingId: buildingId,
      buildingName: buildingName,
      floorsCount: floorsCount,
    ),
  );
}

class _Rooms extends StatefulWidget {
  const _Rooms({
    super.key,
    required this.buildingId,
    required this.buildingName,
    required this.floorsCount,
  });
  final String buildingId;
  final String buildingName;
  final int floorsCount;
  @override
  State<_Rooms> createState() => _RoomsState();
}

class _RoomsState extends State<_Rooms> {
  final _data = CampusRemoteDataSource();
  late final String? _token = ApiClientProvider.session.token;
  late Future<List<Room>> _rooms = _data.getRooms(widget.buildingId);
  bool _busy = false;
  bool _closing = false;
  bool get _authorized =>
      mounted &&
      _token != null &&
      _token == ApiClientProvider.session.token &&
      ApiClientProvider.session.isAuthenticated &&
      AppPermission.manageUsers.allows(
        ApiClientProvider.session.currentUser?.role,
      );

  void _reload() {
    if (_authorized) setState(() => _rooms = _data.getRooms(widget.buildingId));
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    if (!_authorized) {
      if (mounted) Navigator.pop(context, 0);
      return;
    }
    try {
      final rooms = await _data.getRooms(widget.buildingId);
      if (mounted)
        Navigator.pop(
          context,
          rooms.fold<int>(
            0,
            (max, room) => room.floor > max ? room.floor : max,
          ),
        );
    } catch (_) {
      if (mounted) Navigator.pop(context, 0);
    }
  }

  Future<void> _edit([Room? room]) async {
    if (!_authorized || _busy) return;
    try {
      final categories = await _data.getCategories();
      if (!mounted || !_authorized) return;
      final result = await showDialog<_RoomFormResult>(
        context: context,
        builder: (_) => _RoomFormDialog(
          room: room,
          categories: categories,
          floorsCount: widget.floorsCount,
        ),
      );
      if (result == null || !_authorized) return;
      setState(() => _busy = true);
      final payload = <String, Object?>{
        'buildingId': widget.buildingId,
        'name': result.name,
        'floor': result.floor,
        'categoryId': result.categoryId,
      };
      if (room == null) {
        await _data.createRoom(payload);
      } else {
        await _data.updateRoom(room.id, payload);
      }
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la sala: $error')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(Room room) async {
    if (!_authorized || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sala'),
        content: Text('¿Eliminar “${room.name}” del piso ${room.floor}?'),
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
      await _data.deleteRoom(room.id);
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar la sala: $error')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<int>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _close();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text('Salas · ${widget.buildingName}'),
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: _close,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(onPressed: _close, child: const Text('Listo')),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Crear sala',
            onPressed: _busy ? null : () => _edit(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder<List<Room>>(
        future: _rooms,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
              child: TextButton(
                onPressed: _reload,
                child: const Text(
                  'No se pudieron cargar las salas. Reintentar',
                ),
              ),
            );
          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty)
            return const Center(
              child: Text('Este edificio todavía no tiene salas.'),
            );
          final groups = <int, List<Room>>{};
          for (final room in rooms) {
            groups.putIfAbsent(room.floor, () => []).add(room);
          }
          final floors = groups.keys.toList()..sort();
          return ListView(
            children: [
              for (final floor in floors) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                  child: Text(
                    'Piso $floor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                for (final room in groups[floor]!)
                  ListTile(
                    title: Text(room.name),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Editar sala',
                          onPressed: _busy ? null : () => _edit(room),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Eliminar sala',
                          onPressed: _busy ? null : () => _delete(room),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _RoomFormResult {
  const _RoomFormResult(this.name, this.floor, this.categoryId);
  final String name;
  final int floor;
  final String? categoryId;
}

class _RoomFormDialog extends StatefulWidget {
  const _RoomFormDialog({
    required this.room,
    required this.categories,
    required this.floorsCount,
  });
  final Room? room;
  final List<Category> categories;
  final int floorsCount;
  @override
  State<_RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends State<_RoomFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.room?.name ?? '');
  late final _floor = TextEditingController(text: '${widget.room?.floor ?? 1}');
  late String? _categoryId = widget.room?.categoryId.isEmpty == true
      ? null
      : widget.room?.categoryId;
  @override
  void dispose() {
    _name.dispose();
    _floor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.room == null ? 'Nueva sala' : 'Editar sala'),
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            maxLength: 20,
            decoration: const InputDecoration(labelText: 'Nombre de la sala'),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Campo obligatorio'
                : v.trim().length > 20
                ? 'Máximo 20 caracteres'
                : null,
          ),
          TextFormField(
            controller: _floor,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Piso (1–${widget.floorsCount})',
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1 || n > widget.floorsCount
                  ? 'Piso fuera del edificio'
                  : null;
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Sin categoría'),
              ),
              if (_categoryId != null &&
                  !widget.categories.any(
                    (category) => category.id == _categoryId,
                  ))
                DropdownMenuItem(
                  value: _categoryId,
                  child: const Text('Categoría actual no disponible'),
                ),
              ...widget.categories.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            _RoomFormResult(
              _name.text.trim(),
              int.parse(_floor.text),
              _categoryId,
            ),
          );
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
