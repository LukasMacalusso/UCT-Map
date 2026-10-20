import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/env_config.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../data/models/building_model.dart';
import '../../../data/models/campus_model.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/campus.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Rutas reales del microservicio de Campus (vía Gateway). Se consultan
  // directo desde presentation para no tocar api_endpoints.dart.
  static const String _campusesPath = '/api/campus/campuses';
  static const String _buildingsPath = '/api/campus/buildings';

  /// Lado (en grados) de la caja que delimita la zona navegable del campus
  /// seleccionado. La camara puede moverse y hacer zoom, pero su centro no
  /// puede salir de esta caja.
  static const double _campusSpan = 0.006;

  static const EdgeInsets _fitPadding = EdgeInsets.all(24);
  static const Color _primaryColor = Color(0xFF003865);

  /// Centro por defecto (Temuco) mientras no haya campus desde el backend.
  static final LatLngBounds _defaultArea = _areaForPoint(
    const LatLng(-38.7359, -72.5904),
  );

  final MapController _mapController = MapController();

  List<Campus> _campuses = [];
  Campus? _selectedCampus;
  List<Building> _buildings = [];

  bool _loading = true;

  /// El MapController lanza excepcion si se usa antes de que el mapa se haya
  /// renderizado al menos una vez.
  bool _mapReady = false;

  /// Evita la recursión al corrigir la cámara desde [_onPositionChanged].
  bool _clamping = false;

  @override
  void initState() {
    super.initState();

    // Los datos de Campus exigen token: se espera a que la sesión esté
    // restaurada antes de consultar.
    ApiClientProvider.session.ready.then((_) {
      if (mounted) _loadCampuses();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final campus = _selectedCampus;
      if (campus != null) {
        _fitCameraTo(campus);
      }

      setState(() => _mapReady = true);
    });
  }

  // Caja de [span] grados alrededor de un punto.
  static LatLngBounds _areaForPoint(LatLng point) => LatLngBounds(
        LatLng(point.latitude - _campusSpan / 2, point.longitude - _campusSpan / 2),
        LatLng(point.latitude + _campusSpan / 2, point.longitude + _campusSpan / 2),
      );

  // Zona navegable: la del campus seleccionado segun sus coordenadas en la BD.
  LatLngBounds _areaFor(Campus campus) =>
      _areaForPoint(LatLng(campus.latitude, campus.longitude));

  // Mantiene el centro de la camara dentro del area del campus: se puede
  // mover y hacer zoom, pero no salir de la zona.
  //
  // No se usa MapOptions.cameraConstraint porque flutter_map 8.3.2 valida esa
  // restriccion en cada reconstruccion (MapControllerImpl.options) y lanza un
  // assert si la camara queda fuera, algo que ocurre con cualquier setState
  // mientras el usuario arrastra el mapa mas alla del limite.
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (_clamping) return;

    final campus = _selectedCampus;
    if (campus == null) return;

    final area = _areaFor(campus);
    final latitude =
        camera.center.latitude.clamp(area.south, area.north).toDouble();
    final longitude =
        camera.center.longitude.clamp(area.west, area.east).toDouble();

    if (latitude == camera.center.latitude &&
        longitude == camera.center.longitude) {
      return;
    }

    _clamping = true;
    _mapController.move(LatLng(latitude, longitude), camera.zoom);
    _clamping = false;
  }

  // Campus del microservicio (GET /api/campus/campuses).
  Future<List<Campus>> _fetchCampuses() async {
    final json = await ApiClientProvider.apiClient.getJson<List<dynamic>>(
      _campusesPath,
    );

    return json
        .whereType<Map<String, dynamic>>()
        .map(CampusModel.fromJson)
        .toList();
  }

  // Edificios de un campus (GET /api/campus/buildings?campusId=).
  Future<List<Building>> _fetchBuildings(String campusId) async {
    final json = await ApiClientProvider.apiClient.getJson<List<dynamic>>(
      _buildingsPath,
      queryParameters: {'campusId': campusId},
    );

    return json
        .whereType<Map<String, dynamic>>()
        .map(BuildingModel.fromJson)
        .toList();
  }

  Future<void> _loadCampuses() async {
    setState(() => _loading = true);

    List<Campus> campuses;
    try {
      campuses = await _fetchCampuses();
    } catch (_) {
      campuses = [];
    }

    if (!mounted) return;

    final selected = campuses.isNotEmpty ? campuses.first : null;

    setState(() {
      _campuses = campuses;
      _selectedCampus = selected;
      _buildings = [];
      _loading = false;
    });

    if (selected != null) {
      _fitCameraTo(selected);
      await _loadBuildings(selected.id);
    }
  }

  Future<void> _loadBuildings(String campusId) async {
    try {
      final buildings = await _fetchBuildings(campusId);

      if (!mounted) return;

      setState(() {
        _buildings = buildings;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _buildings = [];
        });
      }
    }
  }

  void _selectCampus(Campus campus) {
    Navigator.pop(context);

    setState(() {
      _selectedCampus = campus;
      _buildings = [];
    });

    _fitCameraTo(campus);
    _loadBuildings(campus.id);
  }

  // Encuadra la camara sobre la zona del campus.
  void _fitToCampus(Campus? campus) {
    if (campus == null || !_mapReady) return;

    _fitCameraTo(campus);
  }

  void _fitCameraTo(Campus campus) {
    _mapController.fitCamera(
      CameraFit.bounds(bounds: _areaFor(campus), padding: _fitPadding),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campus = _selectedCampus;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: campus == null
                ? _defaultArea.center
                : LatLng(campus.latitude, campus.longitude),
            initialZoom: 16,
            maxZoom: 19,
            onPositionChanged: _onPositionChanged,
            initialCameraFit: CameraFit.bounds(
              bounds: campus == null ? _defaultArea : _areaFor(campus),
              padding: _fitPadding,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: EnvConfig.mapTileUrl,
              userAgentPackageName: 'cl.cl.uct.uct_map',
            ),

            MarkerLayer(
              markers: [
                if (campus != null) _campusMarker(campus),
                ..._buildings.asMap().entries.map(
                      (entry) => _buildingMarker(entry.key + 1, entry.value),
                    ),
              ],
            ),
          ],
        ),

        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: _primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      campus?.name ?? 'Cargando campus...',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Cambiar Campus',
                    onPressed: _campuses.isEmpty
                        ? null
                        : () => _showCampusSelector(context),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (_loading)
          const Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text('Cargando campus...'),
                ),
              ),
            ),
          ),

        Positioned(
          right: 16,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'map_layers',
                backgroundColor: Colors.white,
                foregroundColor: _primaryColor,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selección de capas de mapa')),
                  );
                },
                tooltip: 'Capas',
                child: const Icon(Icons.layers_outlined),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                heroTag: 'map_gps',
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                onPressed: () {
                  _fitToCampus(_selectedCampus);
                },
                tooltip: 'Centrar campus',
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Marker _campusMarker(Campus campus) {
    return Marker(
      point: LatLng(campus.latitude, campus.longitude),
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: () => _showCampusInfo(campus),
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: _primaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.school, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }

  Marker _buildingMarker(int number, Building building) {
    return Marker(
      point: LatLng(building.latitude, building.longitude),
      width: 38,
      height: 38,
      child: GestureDetector(
        onTap: () => _showBuildingInfo(number, building),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: _primaryColor, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  void _showCampusInfo(Campus campus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school, color: _primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      campus.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(campus.address),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showBuildingInfo(int number, Building building) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number. ${building.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('${building.floorsCount} pisos'),
              const SizedBox(height: 4),
              Text('${building.rooms.length} salas'),
              const SizedBox(height: 12),
              const Text(
                'Id',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              SelectableText(building.id),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCampusSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona un Campus',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._campuses.map((campus) {
                final isSelected = campus.id == _selectedCampus?.id;

                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.location_on : Icons.location_on_outlined,
                    color: isSelected ? _primaryColor : null,
                  ),
                  title: Text(
                    campus.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(campus.address),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () => _selectCampus(campus),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}