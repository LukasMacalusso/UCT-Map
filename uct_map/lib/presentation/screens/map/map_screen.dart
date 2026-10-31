import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/building_model.dart';
import '../../../data/models/campus_model.dart';
import '../../../data/models/campus_location_dto.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../data/services/walking_directions.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/campus.dart';
import 'widgets/building_detail_sheet.dart';
import 'widgets/campus_search_sheet.dart';
import 'widgets/campus_map_view.dart';

/// Coordina la selección de campus, las consultas y los paneles.
/// No dibuja teselas ni marcadores: eso corresponde a CampusMapView.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.selectedCampus});
  final ValueNotifier<Campus?>? selectedCampus;

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  static const String _campusesPath = '/api/campus/campuses';
  static const String _buildingsPath = '/api/campus/buildings';
  static const Color _primaryColor = Color(0xFF003865);

  final GlobalKey<CampusMapViewState> _mapKey = GlobalKey<CampusMapViewState>();
  List<Campus> _campuses = [];
  Campus? _selectedCampus;
  List<Building> _buildings = [];
  List<StructureLocationDto> _structures = [];
  String? _structuresError;
  int _structureRequest = 0;
  bool _loading = true;
  String? _error;
  bool _loadingBuildings = false;
  int _buildingRequest = 0;
  final WalkingDirections _directions = WalkingDirections();
  WalkingRoute? _route;
  Building? _routeOrigin;
  Building? _routeDestination;
  String? _routeDestinationName;
  bool _loadingRoute = false;
  bool _locating = false;
  int _routeRequest = 0;

  @override
  void dispose() {
    widget.selectedCampus?.removeListener(_externalCampusChanged);
    _routeRequest++;
    _directions.dispose();
    super.dispose();
  }

  void _clearRoute({bool restoreCamera = true}) {
    _routeRequest++;
    setState(() {
      _route = null;
      _routeOrigin = null;
      _routeDestination = null;
      _routeDestinationName = null;
      _loadingRoute = false;
    });
    final campus = _selectedCampus;
    if (restoreCamera && campus != null) {
      _mapKey.currentState?.fitToCampus(campus);
    }
  }

  Future<void> _chooseRoute() async {
    if (_buildings.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se necesitan al menos dos edificios en este campus.'),
        ),
      );
      return;
    }
    Building? origin = _routeOrigin;
    Building? destination = _routeDestination;
    final selected = await showDialog<List<Building>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Cómo llegar'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Building>(
                  initialValue: origin,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Desde'),
                  items: _buildings
                      .map(
                        (b) => DropdownMenuItem(value: b, child: Text(b.name)),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => origin = value),
                ),
                DropdownButtonFormField<Building>(
                  initialValue: destination,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Hasta'),
                  items: _buildings
                      .map(
                        (b) => DropdownMenuItem(value: b, child: Text(b.name)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => destination = value),
                ),
                if (origin != null && origin?.id == destination?.id)
                  const Text('Selecciona dos edificios distintos.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed:
                    origin == null ||
                        destination == null ||
                        origin?.id == destination?.id
                    ? null
                    : () => Navigator.pop(context, [origin!, destination!]),
                child: const Text('Ver ruta'),
              ),
            ],
          );
        },
      ),
    );
    if (!mounted ||
        selected == null ||
        selected.first.campusId != _selectedCampus?.id)
      return;
    final request = ++_routeRequest;
    setState(() {
      _loadingRoute = true;
      _route = null;
      _routeOrigin = selected[0];
      _routeDestination = selected[1];
      _routeDestinationName = selected[1].name;
    });
    try {
      final route = await _directions.route(selected[0], selected[1]);
      if (!mounted || request != _routeRequest) return;
      setState(() {
        _route = route;
        _loadingRoute = false;
      });
      _mapKey.currentState?.fitRoute(route.coordinates);
    } on DirectionsException catch (error) {
      if (!mounted || request != _routeRequest) return;
      setState(() => _loadingRoute = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const DirectionsException('Activa la ubicación del dispositivo.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DirectionsException(
        'Activa el permiso de ubicación en los ajustes del dispositivo o del navegador.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const DirectionsException(
        'Necesitamos permiso de ubicación para continuar.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await _currentPosition();
      if (!mounted) return;
      await _mapKey.currentState?.focusOnLocation(
        position.latitude,
        position.longitude,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is DirectionsException
          ? error.message
          : 'No se pudo obtener tu ubicación. Inténtalo nuevamente.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _routeFromLocation(Building destination) => _routeToLocation(
    destination.name,
    destination.latitude,
    destination.longitude,
    building: destination,
  );

  Future<void> _routeToLocation(
    String name,
    double latitude,
    double longitude, {
    Building? building,
  }) async {
    final request = ++_routeRequest;
    setState(() {
      _loadingRoute = true;
      _route = null;
      _routeOrigin = null;
      _routeDestination = building;
      _routeDestinationName = name;
    });
    try {
      final position = await _currentPosition();
      if (!mounted || request != _routeRequest) return;
      final route = await _directions.routeBetweenCoordinates(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );
      if (!mounted || request != _routeRequest) return;
      setState(() {
        _route = route;
        _loadingRoute = false;
      });
      _mapKey.currentState?.fitRoute(route.coordinates);
    } catch (error) {
      if (!mounted || request != _routeRequest) return;
      setState(() => _loadingRoute = false);
      final message = error is DirectionsException
          ? error.message
          : 'No se pudo obtener tu ubicación. Inténtalo nuevamente.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void initState() {
    super.initState();
    widget.selectedCampus?.addListener(_externalCampusChanged);
    ApiClientProvider.session.ready.then((_) {
      if (mounted) _loadCampuses();
    });
  }

  Future<void> _openCampusSearch() async {
    final result = await showModalBottomSheet<CampusSearchResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          CampusSearchSheet(buildings: _buildings, structures: _structures),
    );
    if (!mounted || result == null) return;
    showSearchResult(result);
  }

  void showSearchResult(CampusSearchResult result) {
    if (result.structure != null) {
      _mapKey.currentState?.focusOnStructure(result.structure!);
      _showStructureDetail(result.structure!);
      return;
    }
    final building = result.building;
    if (building == null) return;
    _mapKey.currentState?.focusOnBuilding(building);
    if (result.roomCode != null) {
      showRoomDetail(context, building, {
        'name': result.roomCode,
        if (result.roomFloor != null) 'floor': result.roomFloor,
      }, () => _routeFromLocation(building));
    } else {
      final index = _buildings.indexWhere((item) => item.id == building.id);
      showBuildingDetailSheet(
        context,
        index < 0 ? 1 : index + 1,
        building,
        onDirections: () => _routeFromLocation(building),
      );
    }
  }

  Future<List<Campus>> _fetchCampuses() async {
    final json = await ApiClientProvider.apiClient.getJson<List<dynamic>>(
      _campusesPath,
    );
    return json
        .whereType<Map<String, dynamic>>()
        .map(CampusModel.fromJson)
        .toList();
  }

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
    setState(() {
      _loading = true;
      _error = null;
    });
    List<Campus> campuses;
    try {
      campuses = await _fetchCampuses();
    } catch (error) {
      if (!mounted) return;
      debugPrint('[UCT Map] Error al cargar campus: $error');
      setState(() {
        _loading = false;
        _error = _errorMessage(error, 'campus');
      });
      return;
    }
    if (!mounted) return;
    final currentId = widget.selectedCampus?.value?.id;
    final matches = campuses.where((campus) => campus.id == currentId);
    final selected = matches.isNotEmpty
        ? matches.first
        : (campuses.isNotEmpty ? campuses.first : null);
    setState(() {
      _campuses = campuses;
      _selectedCampus = selected;
      _buildings = [];
      _loading = false;
    });
    if (selected != null) {
      widget.selectedCampus?.value = selected;
      _loadStructures(selected.id);
      await _loadBuildings(selected.id);
    }
  }

  Future<void> _loadStructures(String campusId) async {
    final request = ++_structureRequest;
    setState(() {
      _structures = [];
      _structuresError = null;
    });
    try {
      final structures = await CampusRemoteDataSource().getStructureLocations(
        campusId: campusId,
      );
      if (!mounted ||
          request != _structureRequest ||
          _selectedCampus?.id != campusId)
        return;
      setState(() => _structures = structures);
    } catch (_) {
      if (!mounted ||
          request != _structureRequest ||
          _selectedCampus?.id != campusId)
        return;
      setState(
        () => _structuresError =
            'No se pudieron cargar los servicios del campus.',
      );
    }
  }

  void _showStructureDetail(StructureLocationDto structure) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                structure.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                structure.categoryName.isEmpty
                    ? 'Servicio del campus'
                    : structure.categoryName,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _routeToLocation(
                      structure.name,
                      structure.location.latitude,
                      structure.location.longitude,
                    );
                  },
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Cómo llegar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadBuildings(String campusId) async {
    final request = ++_buildingRequest;
    setState(() {
      _loadingBuildings = true;
      _error = null;
    });
    try {
      final buildings = await _fetchBuildings(campusId);
      if (!mounted ||
          request != _buildingRequest ||
          _selectedCampus?.id != campusId) {
        return;
      }
      setState(() {
        _buildings = buildings;
        _loadingBuildings = false;
      });
    } catch (error) {
      debugPrint('[UCT Map] Error al cargar edificios: $error');
      if (mounted &&
          request == _buildingRequest &&
          _selectedCampus?.id == campusId) {
        setState(() {
          _buildings = [];
          _loadingBuildings = false;
          _error = _errorMessage(error, 'edificios');
        });
      }
    }
  }

  String _errorMessage(Object error, String item) {
    if (error is NetworkException) {
      return 'No se pudo conectar al servidor para cargar $item.';
    }
    if (error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      return 'No tienes acceso para cargar $item. Revisa tu sesión.';
    }
    return 'No se pudieron cargar $item. Revisa el servidor e intenta nuevamente.';
  }

  void _selectCampus(Campus campus) {
    Navigator.pop(context);
    _changeCampus(campus);
  }

  void _externalCampusChanged() {
    final campus = widget.selectedCampus?.value;
    if (campus != null && campus.id != _selectedCampus?.id)
      _changeCampus(campus);
  }

  void _changeCampus(Campus campus) {
    if (campus.id == _selectedCampus?.id) return;
    _clearRoute(restoreCamera: false);
    setState(() {
      _selectedCampus = campus;
      _buildings = [];
    });
    _loadBuildings(campus.id);
    _loadStructures(campus.id);
    widget.selectedCampus?.value = campus;
  }

  @override
  Widget build(BuildContext context) {
    final campus = _selectedCampus;
    return Stack(
      children: [
        CampusMapView(
          key: _mapKey,
          campus: campus,
          buildings: _buildings,
          structures: _structures,
          onStructureTap: _showStructureDetail,
          routeCoordinates: _route?.coordinates,
          onCampusTap: _showCampusInfo,
          onBuildingTap: (number, building) => showBuildingDetailSheet(
            context,
            number,
            building,
            onDirections: () => _routeFromLocation(building),
          ),
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
        if (_error != null)
          Positioned(
            top: 155,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!)),
                    TextButton(
                      onPressed: () {
                        final campus = _selectedCampus;
                        if (campus == null) {
                          _loadCampuses();
                        } else {
                          _loadBuildings(campus.id);
                        }
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_loadingBuildings)
          const Positioned(
            top: 155,
            left: 16,
            right: 16,
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_structuresError != null)
          Positioned(
            top: 205,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(child: Text(_structuresError!)),
                    TextButton(
                      onPressed: campus == null
                          ? null
                          : () => _loadStructures(campus.id),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: _route != null || _loadingRoute ? 240 : 24,
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
                onPressed: _locating ? null : _locateMe,
                tooltip: 'Mi ubicación',
                child: _locating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        Positioned(
          top: 88,
          left: 16,
          right: 16,
          child: FilledButton.icon(
            onPressed: _openCampusSearch,
            icon: const Icon(Icons.search),
            label: const Text('Buscar edificio o sala'),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_route != null || _loadingRoute)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadingRoute) ...[
                      const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Buscando ruta...'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_route != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${(_route!.duration / 60).ceil()} min',
                                  style: const TextStyle(
                                    color: _primaryColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _route!.distance >= 1000
                                      ? '${(_route!.distance / 1000).toStringAsFixed(1)} km a pie'
                                      : '${_route!.distance.round()} m a pie',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFFCD00),
                            child: Icon(
                              Icons.directions_walk,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        '${_routeOrigin?.name ?? 'Mi ubicación'} → ${_routeDestinationName ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        if (_route != null || _loadingRoute) ...[
                          OutlinedButton.icon(
                            onPressed: _clearRoute,
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Cancelar ruta'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _primaryColor,
                            ),
                            onPressed: _loadingRoute ? null : _chooseRoute,
                            icon: const Icon(Icons.directions_walk),
                            label: Text(
                              _route == null ? 'Cómo llegar' : 'Cambiar ruta',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCampusInfo(Campus campus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
      ),
    );
  }

  void _showCampusSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => Padding(
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
      ),
    );
  }
}
