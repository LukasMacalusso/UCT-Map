import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../data/models/campus_location_dto.dart';
import '../../../data/models/report_dto.dart';
import '../../../data/models/lost_object_dto.dart';
import '../../../data/repositories/reports_repository_impl.dart';
import '../../../data/repositories/lost_objects_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/campus.dart';
import '../login/session_required_view.dart';
import '../map/campuses/campus_area_registry.dart';
import 'admin_buildings_screen.dart';
import 'admin_structures_screen.dart';
import 'admin_categories_screen.dart';
import 'campus_location_picker_screen.dart';

/// Campus inicial para la revisión administrativa; no altera los datos.
Campus? preferredAdminCampus(List<Campus> campuses, {String? previousId}) =>
    campuses.where((c) => c.id == previousId).firstOrNull ??
    campuses
        .where(
          (c) =>
              c.id == '855f802e-311d-418e-b1a3-80cc2c360625' ||
              c.name.toLowerCase().contains('juan pablo'),
        )
        .firstOrNull ??
    campuses.firstOrNull;

/// Gestión de campus disponible exclusivamente en la interfaz de administrador.
class AdminCampusScreen extends StatelessWidget {
  const AdminCampusScreen({super.key});
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => const _AdminCampus(),
  );
}

class _AdminCampus extends StatefulWidget {
  const _AdminCampus();
  @override
  State<_AdminCampus> createState() => _AdminCampusState();
}

class _AdminCampusState extends State<_AdminCampus> {
  final _session = ApiClientProvider.session;
  final _campus = CampusRemoteDataSource();
  final _reports = ReportsRepositoryImpl();
  final _objects = LostObjectsRepositoryImpl();
  late final String? _token = _session.token;
  List<Campus> _campuses = [];
  Campus? _selected;
  bool _loading = true;
  String? _error;
  bool _objectsMode = false;
  List<Map<String, Object>> _points = [];
  int _revision = 0;
  MapboxMap? _map;
  bool _styleReady = false;
  final Set<MapboxMap> _drawnMaps = {};

  bool get _authorized =>
      mounted &&
      _token != null &&
      _session.token == _token &&
      _session.isAuthenticated &&
      AppPermission.manageUsers.allows(_session.currentUser?.role);

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  @override
  void dispose() {
    _revision++;
    super.dispose();
  }

  Future<void> _loadCampuses() async {
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final campuses = await _campus.getCampuses();
      if (!_authorized || revision != _revision) return;
      final previousId = _selected?.id;
      setState(() {
        _campuses = campuses;
        _selected = preferredAdminCampus(campuses, previousId: previousId);
        _loading = false;
      });
      if (_selected != null) await _loadHeatmap();
    } catch (_) {
      if (_authorized && revision == _revision)
        setState(() {
          _loading = false;
          _error = 'No se pudieron cargar los campus.';
        });
    }
  }

  Future<void> _loadHeatmap() async {
    final campus = _selected;
    if (campus == null || !_authorized) return;
    final revision = ++_revision;
    final objectsMode = _objectsMode;
    setState(() {
      _loading = true;
      _error = null;
      _points = [];
      _map = null;
      _styleReady = false;
    });
    try {
      final buildings = await _campus.getBuildingLocations(campusId: campus.id);
      final structures = await _campus.getStructureLocations(
        campusId: campus.id,
      );
      final counts = <String, int>{};
      var page = 1;
      while (true) {
        if (!_authorized || revision != _revision) return;
        if (objectsMode) {
          final batch = await _objects.getLostObjects(
            filter: LostObjectFilterParams(page: page),
          );
          for (final object in batch.items) {
            counts.update(object.structureId, (v) => v + 1, ifAbsent: () => 1);
          }
          if (!batch.hasNextPage) break;
        } else {
          final batch = await _reports.getReports(
            filter: ReportFilterParams(page: page),
          );
          // Reportes con queja: excluir tickets creados solo para objetos.
          for (final ticket in batch.items.where(
            (t) => t.complaintDetails != null,
          )) {
            counts.update(
              ticket.structureRefId,
              (v) => v + 1,
              ifAbsent: () => 1,
            );
          }
          if (!batch.hasNextPage) break;
        }
        page++;
      }
      if (!_authorized || revision != _revision) return;
      final points = <Map<String, Object>>[];
      for (final b in buildings) {
        if ((counts[b.id] ?? 0) > 0)
          points.add({
            'name': b.name,
            'count': counts[b.id]!,
            'lat': b.location.latitude,
            'lon': b.location.longitude,
          });
      }
      for (final s in structures) {
        if ((counts[s.id] ?? 0) > 0)
          points.add({
            'name': s.name,
            'count': counts[s.id]!,
            'lat': s.location.latitude,
            'lon': s.location.longitude,
          });
      }
      setState(() {
        _points = points;
        _loading = false;
      });
    } catch (_) {
      if (_authorized && revision == _revision)
        setState(() {
          _loading = false;
          _error = 'No se pudo cargar el mapa de calor. Reintenta.';
        });
    }
  }

  Future<void> _draw() async {
    final map = _map;
    if (map == null || !_styleReady || !_authorized || !_drawnMaps.add(map))
      return;
    final data = jsonEncode({
      'type': 'FeatureCollection',
      'features': _points
          .map(
            (p) => {
              'type': 'Feature',
              'properties': {'name': p['name'], 'count': p['count']},
              'geometry': {
                'type': 'Point',
                'coordinates': [p['lon'], p['lat']],
              },
            },
          )
          .toList(),
    });
    try {
      // El mismo estilo Mapbox Standard utilizado por el mapa principal.
      try {
        await map.setStyleImportConfigProperties('basemap', {
          'lightPreset': 'day',
          'theme': 'default',
          'show3dBuildings': true,
          'showPointOfInterestLabels': false,
          'colorBuildings': '#C6D2DE',
          'colorLand': '#F4F6F8',
          'colorEducation': '#E5EDF7',
          'colorGreenspace': '#DCEAD8',
          'colorWater': '#B6DDE9',
          'colorRoads': '#FFFFFF',
        });
      } catch (_) {
        // El mapa sigue disponible si la versión del estilo omite una opción.
      }
      await map.addSource(GeoJsonSource(id: 'admin-heat', data: data));
      await map.addLayer(
        CircleLayer(
          id: 'admin-heat-circles',
          sourceId: 'admin-heat',
          circleColorExpression: [
            'step',
            ['get', 'count'],
            '#facc15',
            3,
            '#f97316',
            6,
            '#dc2626',
          ],
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['get', 'count'],
            1,
            12,
            10,
            30,
          ],
          circleOpacity: 0.72,
          circleStrokeColor: 0xffffffff,
          circleStrokeWidth: 1,
        ),
      );
    } catch (_) {
      _drawnMaps.remove(map);
      if (_authorized && map == _map)
        setState(() => _error = 'No se pudo dibujar el mapa de calor.');
    }
  }

  Future<void> _edit() async {
    final campus = _selected;
    if (campus == null || !_authorized) return;
    try {
      final data = await ApiClientProvider.apiClient
          .getJson<Map<String, dynamic>>('/api/campus/campuses/${campus.id}');
      if (!mounted || !_authorized) return;
      final updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => _EditCampus(data: data, token: _token!),
        ),
      );
      if (_authorized && updated == true) await _loadCampuses();
    } catch (_) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar el campus para editarlo.'),
          ),
        );
    }
  }

  Future<void> _createCampus() async {
    if (!_authorized) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditCampus(data: null, token: _token!),
      ),
    );
    if (_authorized && saved == true) await _loadCampuses();
  }

  Future<void> _deleteCampus() async {
    final campus = _selected;
    if (campus == null || !_authorized) return;
    try {
      final buildings = await _campus.getBuildings(campus.id);
      final structures = await _campus.getStructures(campus.id);
      if (!mounted || !_authorized) return;
      if (buildings.isNotEmpty || structures.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se puede eliminar: contiene ${buildings.length} edificios y ${structures.length} estructuras. Elimínalos primero.',
            ),
          ),
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Eliminar campus'),
          content: Text(
            '¿Eliminar “${campus.name}”? Esta acción no se puede deshacer.',
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
      await _campus.deleteCampus(campus.id);
      if (_authorized) await _loadCampuses();
    } catch (error) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException && error.statusCode == 409
                  ? 'El campus tiene datos asociados y no se puede eliminar.'
                  : 'No se pudo eliminar el campus. Actualiza la lista e inténtalo nuevamente.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Administrar campus'),
      actions: [
        IconButton(
          tooltip: 'Crear campus',
          onPressed: _loading ? null : _createCampus,
          icon: const Icon(Icons.add),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selected?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Campus'),
                  items: _campuses
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (id) {
                          if (id == null) return;
                          setState(
                            () => _selected = _campuses.firstWhere(
                              (c) => c.id == id,
                            ),
                          );
                          _loadHeatmap();
                        },
                ),
              ),
              IconButton(
                tooltip: 'Editar campus',
                onPressed: _loading ? null : _edit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Eliminar campus',
                onPressed: _loading ? null : _deleteCampus,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [
            TextButton.icon(
              onPressed: _loading || _selected == null
                  ? null
                  : () async {
                      final selected = _selected!;
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AdminBuildingsScreen(campus: selected),
                        ),
                      );
                      if (_authorized) await _loadHeatmap();
                    },
              icon: const Icon(Icons.apartment),
              label: const Text('Edificios'),
            ),
            TextButton.icon(
              onPressed: _loading || _selected == null
                  ? null
                  : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              AdminStructuresScreen(campus: _selected!),
                        ),
                      );
                      if (_authorized) await _loadHeatmap();
                    },
              icon: const Icon(Icons.place_outlined),
              label: const Text('Estructuras'),
            ),
            TextButton.icon(
              onPressed: _loading
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AdminCategoriesScreen(),
                      ),
                    ),
              icon: const Icon(Icons.category_outlined),
              label: const Text('Categorías'),
            ),
          ],
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Reportes')),
            ButtonSegment(value: true, label: Text('Objetos')),
          ],
          selected: {_objectsMode},
          onSelectionChanged: _loading
              ? null
              : (v) {
                  setState(() => _objectsMode = v.first);
                  _loadHeatmap();
                },
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Conteo por ubicación · amarillo: menor · rojo: mayor'),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(
                    onPressed: _loadCampuses,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else if (_selected == null)
          const Expanded(
            child: Center(child: Text('No hay campus disponibles.')),
          )
        else
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: MapWidget(
                    key: ValueKey('${_selected!.id}-$_objectsMode-$_revision'),
                    styleUri: MapboxStyles.STANDARD,
                    viewport: CameraViewportState(
                      center: Point(
                        coordinates: Position(
                          _selected!.longitude,
                          _selected!.latitude,
                        ),
                      ),
                      zoom: areaForCampus(_selected!).initialZoom,
                      pitch: areaForCampus(_selected!).pitch,
                      bearing: areaForCampus(_selected!).bearing,
                    ),
                    onMapCreated: (map) {
                      _map = map;
                      _draw();
                    },
                    onStyleLoadedListener: (_) {
                      _styleReady = true;
                      _draw();
                    },
                  ),
                ),
                if (_points.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No hay registros con ubicación para este campus.',
                    ),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: ListView(
                      children: _points
                          .map(
                            (p) => ListTile(
                              dense: true,
                              title: Text(p['name'].toString()),
                              trailing: Text('${p['count']}'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _EditCampus extends StatefulWidget {
  const _EditCampus({required this.data, required this.token});
  final Map<String, dynamic>? data;
  final String token;
  @override
  State<_EditCampus> createState() => _EditCampusState();
}

class _EditCampusState extends State<_EditCampus> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields = {
    for (final key in [
      'name',
      'address',
      'latitude',
      'longitude',
      'zoom',
      'pitch',
      'bearing',
    ])
      key: TextEditingController(
        text:
            '${widget.data?[key] ?? (key == 'zoom'
                    ? 17
                    : key == 'pitch' || key == 'bearing'
                    ? 0
                    : '')}',
      ),
  };
  bool _busy = false;
  bool get _authorized =>
      ApiClientProvider.session.token == widget.token &&
      ApiClientProvider.session.isAuthenticated &&
      AppPermission.manageUsers.allows(
        ApiClientProvider.session.currentUser?.role,
      );
  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_authorized || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final payload = <String, Object>{
        'name': _fields['name']!.text.trim(),
        'address': _fields['address']!.text.trim(),
        for (final key in ['latitude', 'longitude', 'zoom', 'pitch', 'bearing'])
          key: double.parse(_fields[key]!.text.trim()),
      };
      if (widget.data == null) {
        await CampusRemoteDataSource().createCampus(payload);
      } else {
        await CampusRemoteDataSource().updateCampus(
          widget.data!['id'].toString(),
          payload,
        );
      }
      if (mounted && _authorized) Navigator.pop(context, true);
    } catch (_) {
      if (mounted && _authorized)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo guardar el campus. Revisa los datos y reintenta.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) {
      if (!_authorized)
        return const Scaffold(body: Center(child: Text('La sesión cambió.')));
      const labels = {
        'name': 'Nombre',
        'address': 'Dirección',
        'latitude': 'Latitud',
        'longitude': 'Longitud',
        'zoom': 'Zoom',
        'pitch': 'Inclinación',
        'bearing': 'Orientación',
      };
      const bounds = {
        'latitude': (-90.0, 90.0),
        'longitude': (-180.0, 180.0),
        'zoom': (0.0, 22.0),
        'pitch': (0.0, 85.0),
        'bearing': (-180.0, 180.0),
      };
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.data == null ? 'Crear campus' : 'Editar campus'),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final latitude =
                            double.tryParse(_fields['latitude']!.text) ?? -38.7;
                        final longitude =
                            double.tryParse(_fields['longitude']!.text) ??
                            -72.6;
                        final point = await Navigator.push<CampusCoordinateDto>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CampusLocationPickerScreen(
                              latitude: latitude,
                              longitude: longitude,
                              title: 'Ubicación del campus',
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
              for (final key in labels.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _fields[key],
                    decoration: InputDecoration(labelText: labels[key]),
                    keyboardType: bounds.containsKey(key)
                        ? const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          )
                        : TextInputType.text,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Campo obligatorio';
                      if (!bounds.containsKey(key))
                        return text.length > 100
                            ? 'Máximo 100 caracteres'
                            : null;
                      final n = double.tryParse(text);
                      final range = bounds[key]!;
                      if (n == null ||
                          !n.isFinite ||
                          n < range.$1 ||
                          n > range.$2)
                        return 'Ingresa un valor entre ${range.$1} y ${range.$2}';
                      return null;
                    },
                  ),
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
