import '../../widgets/unsaved_form.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/campus.dart';
import '../../../domain/entities/category.dart';
import '../login/session_required_view.dart';
import 'admin_rooms_screen.dart';
import 'campus_location_picker_screen.dart';
import '../../../data/models/campus_location_dto.dart';

class AdminBuildingsScreen extends StatelessWidget {
  const AdminBuildingsScreen({super.key, required this.campus});
  final Campus campus;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => _Buildings(
      key: ValueKey(ApiClientProvider.session.token),
      campus: campus,
    ),
  );
}

class _Buildings extends StatefulWidget {
  const _Buildings({super.key, required this.campus});
  final Campus campus;
  @override
  State<_Buildings> createState() => _BuildingsState();
}

class _BuildingsState extends State<_Buildings> {
  final _repository = CampusRemoteDataSource();
  final _session = ApiClientProvider.session;
  late final String? _token = _session.token;
  late Future<List<Building>> _buildings = _repository.getBuildings(
    widget.campus.id,
  );
  bool get _authorized =>
      mounted &&
      _token != null &&
      _token == _session.token &&
      _session.isAuthenticated &&
      AppPermission.manageUsers.allows(_session.currentUser?.role);
  void _reload() {
    if (_authorized)
      setState(() => _buildings = _repository.getBuildings(widget.campus.id));
  }

  Future<void> _open(Building building) async {
    if (!_authorized) return;
    try {
      final api = ApiClientProvider.apiClient;
      final detail = await api.getJson<Map<String, dynamic>>(
        '/api/campus/buildings/${building.id}',
      );
      final categories = await _repository.getCategories();
      final rooms = await _repository.getRooms(building.id);
      if (!mounted || !_authorized) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _BuildingEditor(
            detail: detail,
            campusId: widget.campus.id,
            campusLatitude: widget.campus.latitude,
            campusLongitude: widget.campus.longitude,
            categories: categories,
            highestRoomFloor: rooms.fold<int>(
              0,
              (value, room) => room.floor > value ? room.floor : value,
            ),
            token: _token!,
          ),
        ),
      );
      if (result == true && _authorized) _reload();
    } catch (_) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar los datos del edificio.'),
          ),
        );
    }
  }

  Future<void> _create() async {
    if (!_authorized) return;
    try {
      final categories = await _repository.getCategories();
      if (!mounted || !_authorized) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _BuildingEditor(
            detail: null,
            campusId: widget.campus.id,
            campusLatitude: widget.campus.latitude,
            campusLongitude: widget.campus.longitude,
            categories: categories,
            highestRoomFloor: 0,
            token: _token!,
          ),
        ),
      );
      if (result == true && _authorized) _reload();
    } catch (_) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar las categorías.'),
          ),
        );
    }
  }

  Future<void> _delete(Building building) async {
    if (!_authorized) return;
    try {
      final rooms = await _repository.getRooms(building.id);
      if (!mounted || !_authorized) return;
      if (rooms.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se puede eliminar: el edificio contiene ${rooms.length} salas. Elimínalas primero.',
            ),
          ),
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar edificio'),
          content: Text(
            '¿Eliminar “${building.name}”? Esta acción no se puede deshacer.',
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
      if (confirmed != true || !mounted || !_authorized) return;
      await _repository.deleteBuilding(building.id);
      if (_authorized) _reload();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException && error.statusCode == 409
                  ? 'El edificio tiene salas asociadas y no se puede eliminar.'
                  : 'No se pudo eliminar el edificio. Actualiza e inténtalo nuevamente.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Gestionar edificios'),
      actions: [
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        IconButton(
          onPressed: _authorized ? _create : null,
          icon: const Icon(Icons.add),
          tooltip: 'Crear edificio',
        ),
      ],
    ),
    body: FutureBuilder<List<Building>>(
      future: _buildings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text(
                'No se pudieron cargar los edificios. Reintentar',
              ),
            ),
          );
        final buildings = snapshot.data ?? [];
        if (buildings.isEmpty)
          return const Center(child: Text('Este campus no tiene edificios.'));
        return ListView.builder(
          itemCount: buildings.length,
          itemBuilder: (context, index) {
            final building = buildings[index];
            return ListTile(
              title: Text(building.name),
              subtitle: Text('${building.floorsCount} pisos'),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: () => _open(building),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Eliminar',
                    onPressed: () => _delete(building),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              onTap: () => _open(building),
            );
          },
        );
      },
    ),
  );
}

class _BuildingEditor extends StatefulWidget {
  const _BuildingEditor({
    required this.detail,
    required this.campusId,
    required this.campusLatitude,
    required this.campusLongitude,
    required this.categories,
    required this.highestRoomFloor,
    required this.token,
  });
  final Map<String, dynamic>? detail;
  final String campusId;
  final double campusLatitude;
  final double campusLongitude;
  final List<Category> categories;
  final int highestRoomFloor;
  final String token;
  @override
  State<_BuildingEditor> createState() => _BuildingEditorState();
}

class _BuildingEditorState extends State<_BuildingEditor> {
  final _form = GlobalKey<FormState>();
  late final _fields = <String, TextEditingController>{
    for (final key in [
      'name',
      'floorsCount',
      'latitude',
      'longitude',
      'openTime',
      'closeTime',
      'services',
    ])
      key: TextEditingController(
        text:
            '${widget.detail?[key] ?? switch (key) {
                  'floorsCount' => 1,
                  'latitude' => widget.campusLatitude,
                  'longitude' => widget.campusLongitude,
                  _ => '',
                }}',
      ),
  };
  late String? _category = widget.detail?['categoryId']?.toString();
  late int _highestRoomFloor = widget.highestRoomFloor;
  bool _busy = false;
  String? _error;
  bool get _authorized =>
      ApiClientProvider.session.isAuthenticated &&
      ApiClientProvider.session.token == widget.token &&
      AppPermission.manageUsers.allows(
        ApiClientProvider.session.currentUser?.role,
      );
  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  String? _validTime(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d(?:\.\d{1,7})?)?$')
        .hasMatch(text))
      return 'Usa el formato HH:mm';
    return null;
  }

  double _seconds(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 3600 +
        int.parse(parts[1]) * 60 +
        (parts.length > 2 ? double.parse(parts[2]) : 0);
  }

  Future<void> _save() async {
    if (_busy || !_authorized || !_form.currentState!.validate()) return;
    final open = _fields['openTime']!.text.trim();
    final close = _fields['closeTime']!.text.trim();
    if (open.isNotEmpty &&
        close.isNotEmpty &&
        _seconds(open) >= _seconds(close)) {
      setState(() => _error = 'La apertura debe ser anterior al cierre.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final services = _fields['services']!.text.trim();
      final payload = <String, Object?>{
        'campusId': widget.campusId,
        'name': _fields['name']!.text.trim(),
        'floorsCount': int.parse(_fields['floorsCount']!.text.trim()),
        'latitude': double.parse(_fields['latitude']!.text.trim()),
        'longitude': double.parse(_fields['longitude']!.text.trim()),
        'openTime': open.isEmpty ? null : open,
        'closeTime': close.isEmpty ? null : close,
        'services': services.isEmpty ? null : services,
        'categoryId': _category,
      };
      if (widget.detail == null) {
        await _repository.createBuilding(payload);
      } else {
        await _repository.updateBuilding(
          widget.detail!['id'].toString(),
          payload,
        );
      }
      if (mounted && _authorized) Navigator.pop(context, true);
    } catch (error) {
      if (mounted && _authorized) {
        final message = switch (error) {
          ApiException(statusCode: 403) =>
            'No tienes permiso para editar este edificio.',
          ApiException(statusCode: 404) =>
            'El edificio ya no está disponible. Actualiza la lista.',
          ApiException(statusCode: 400) =>
            'El servicio rechazó los datos. Revisa el formulario.',
          NetworkException() =>
            'No se pudo conectar. Comprueba los datos antes de reintentar.',
          _ => 'No se pudo confirmar el cambio. Comprueba los datos antes de reintentar.',
        };
        setState(() => _error = message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  final _repository = CampusRemoteDataSource();
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) {
      if (!_authorized)
        return const Scaffold(body: Center(child: Text('La sesión cambió.')));
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.detail == null ? 'Crear edificio' : 'Editar edificio',
          ),
        ),
        body: UnsavedForm(
          formKey: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final latitude =
                            double.tryParse(_fields['latitude']!.text) ??
                            widget.campusLatitude;
                        final longitude =
                            double.tryParse(_fields['longitude']!.text) ??
                            widget.campusLongitude;
                        final point = await Navigator.push<CampusCoordinateDto>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CampusLocationPickerScreen(
                              latitude: latitude,
                              longitude: longitude,
                              title: 'Ubicación del edificio',
                            ),
                          ),
                        );
                        if (point != null && mounted && _authorized) {
                          _fields['latitude']!.text = point.latitude
                              .toStringAsFixed(6);
                          _fields['longitude']!.text = point.longitude
                              .toStringAsFixed(6);
                        }
                      },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Elegir ubicación en el mapa'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextFormField(
                controller: _fields['name'],
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Campo obligatorio'
                    : v.trim().length > 100
                    ? 'Máximo 100 caracteres'
                    : null,
              ),
              TextFormField(
                controller: _fields['floorsCount'],
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de pisos',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Ingresa al menos 1 piso';
                  if (n < _highestRoomFloor)
                    return 'Hay salas hasta el piso $_highestRoomFloor';
                  return null;
                },
              ),
              for (final key in ['latitude', 'longitude'])
                TextFormField(
                  controller: _fields[key],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: key == 'latitude' ? 'Latitud' : 'Longitud',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    final max = key == 'latitude' ? 90 : 180;
                    return n == null || !n.isFinite || n.abs() > max
                        ? 'Coordenada inválida'
                        : null;
                  },
                ),
              TextFormField(
                controller: _fields['openTime'],
                decoration: const InputDecoration(
                  labelText: 'Apertura (HH:mm, opcional)',
                ),
                validator: _validTime,
              ),
              TextFormField(
                controller: _fields['closeTime'],
                decoration: const InputDecoration(
                  labelText: 'Cierre (HH:mm, opcional)',
                ),
                validator: _validTime,
              ),
              TextFormField(
                controller: _fields['services'],
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Servicios'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Sin categoría'),
                  ),
                  if (_category != null &&
                      !widget.categories.any((c) => c.id == _category))
                    DropdownMenuItem(
                      value: _category,
                      child: const Text('Categoría actual no disponible'),
                    ),
                  ...widget.categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 24),
              if (widget.detail != null)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final result = await Navigator.push<int>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminRoomsScreen(
                                buildingId: widget.detail!['id'].toString(),
                                buildingName: widget.detail!['name'].toString(),
                                floorsCount:
                                    int.tryParse(
                                      _fields['floorsCount']!.text,
                                    ) ??
                                    1,
                              ),
                            ),
                          );
                          if (result != null && mounted)
                            setState(() => _highestRoomFloor = result);
                        },
                  icon: const Icon(Icons.meeting_room_outlined),
                  label: const Text('Gestionar salas y pisos'),
                ),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Guardando…' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
