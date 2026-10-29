import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../data/models/building_model.dart';
import '../../../data/models/campus_model.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/campus.dart';
import 'widgets/building_detail_sheet.dart';
import 'widgets/campus_search_sheet.dart';
import 'widgets/campus_map_view.dart';

/// Coordina la selección de campus, las consultas y los paneles.
/// No dibuja teselas ni marcadores: eso corresponde a CampusMapView.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const String _campusesPath = '/api/campus/campuses';
  static const String _buildingsPath = '/api/campus/buildings';
  static const Color _primaryColor = Color(0xFF003865);

  final GlobalKey<CampusMapViewState> _mapKey = GlobalKey<CampusMapViewState>();
  List<Campus> _campuses = [];
  Campus? _selectedCampus;
  List<Building> _buildings = [];
  bool _loading = true;
  int _buildingRequest = 0;

  @override
  void initState() {
    super.initState();
    ApiClientProvider.session.ready.then((_) {
      if (mounted) _loadCampuses();
    });
  }

  Future<void> _openCampusSearch() async {
    if (_buildings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay edificios cargados para buscar.')),
      );
      return;
    }
    final result = await showModalBottomSheet<CampusSearchResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CampusSearchSheet(buildings: _buildings),
    );
    if (!mounted || result == null) return;
    _mapKey.currentState?.focusOnBuilding(result.building);
    if (result.roomCode != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sala ${result.roomCode} · ${result.building.name}'),
        ),
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
    if (selected != null) await _loadBuildings(selected.id);
  }

  Future<void> _loadBuildings(String campusId) async {
    final request = ++_buildingRequest;
    try {
      final buildings = await _fetchBuildings(campusId);
      if (!mounted ||
          request != _buildingRequest ||
          _selectedCampus?.id != campusId)
        return;
      setState(() => _buildings = buildings);
    } catch (_) {
      if (mounted &&
          request == _buildingRequest &&
          _selectedCampus?.id == campusId) {
        setState(() => _buildings = []);
      }
    }
  }

  void _selectCampus(Campus campus) {
    Navigator.pop(context);
    setState(() {
      _selectedCampus = campus;
      _buildings = [];
    });
    _loadBuildings(campus.id);
  }

  void _fitToCampus() {
    final campus = _selectedCampus;
    if (campus != null) _mapKey.currentState?.fitToCampus(campus);
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
          onCampusTap: _showCampusInfo,
          onBuildingTap: (number, building) =>
              showBuildingDetailSheet(context, number, building),
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
                onPressed: _fitToCampus,
                tooltip: 'Centrar campus',
                child: const Icon(Icons.my_location),
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
