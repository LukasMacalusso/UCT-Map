import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../domain/entities/building.dart';
import '../../../../domain/entities/campus.dart';
import '../campuses/campus_area_registry.dart';

/// Vista cartografica independiente del orquestador MapScreen.
/// Mapbox v3 usa fuentes/capas GeoJSON en vez de AnnotationManager
/// para que los marcadores funcionen tambien en Flutter Web.
class CampusMapView extends StatefulWidget {
  const CampusMapView({
    super.key,
    required this.campus,
    required this.buildings,
    required this.onCampusTap,
    required this.onBuildingTap,
  });

  final Campus? campus;
  final List<Building> buildings;
  final ValueChanged<Campus> onCampusTap;
  final void Function(int number, Building building) onBuildingTap;

  @override
  State<CampusMapView> createState() => CampusMapViewState();
}

class CampusMapViewState extends State<CampusMapView> {
  static const _campusSourceId = 'uct-campus-source';
  static const _buildingSourceId = 'uct-building-source';
  static const _buildingCircleLayerId = 'uct-building-circles';
  static const _buildingTextLayerId = 'uct-building-numbers';
  static const _campusLayerId = 'uct-campus-circle';
  static const _campusTextLayerId = 'uct-campus-icon';

  static const _blue = 0xFF003865;
  static const _yellow = 0xFFEAA221;

  void focusOnBuilding(Building building) {
    final campus = widget.campus;
    if (campus == null || _map == null) return;
    final area = areaForCampus(campus);
    final zoom = 18.5 < area.maxZoom ? 18.5 : area.maxZoom;
    _viewportController.moveTo(
      CameraViewportState(
        center: _position(building.longitude, building.latitude),
        zoom: zoom,
        pitch: area.pitch,
        bearing: area.bearing,
      ),
      transition: EasingViewportTransition(
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  final ViewportController _viewportController = ViewportController();
  MapboxMap? _map;
  GeoJsonSource? _campusSource;
  GeoJsonSource? _buildingSource;
  bool _styleReady = false;
  int _revision = 0;
  int _boundsRevision = 0;

  Point _position(double longitude, double latitude) =>
      Point(coordinates: Position(longitude, latitude));

  int _buildingNumber(int index, Building building) {
    const jp2Buildings = <String, int>{
      'faad': 1,
      'diseño': 2,
      'agustina hidalgo': 3,
      'ricardo ferrando': 7,
      'adalberto salas': 8,
      'waldomerchant': 10,
      'waldo merchant': 10,
      'complejo deportivo': 12,
    };

    if (widget.campus?.id == '855f802e-311d-418e-b1a3-80cc2c360625') {
      final name = building.name.trim().toLowerCase();
      return jp2Buildings[name] ?? index + 1;
    }

    return index + 1;
  }

  String _campusGeoJson() {
    final campus = widget.campus;
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': campus == null
          ? []
          : [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Point',
                  'coordinates': [campus.longitude, campus.latitude],
                },
                'properties': {'campusId': campus.id},
              },
            ],
    });
  }

  String _buildingGeoJson() {
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': [
        for (final entry in widget.buildings.asMap().entries)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [entry.value.longitude, entry.value.latitude],
            },
            'properties': {
              'buildingId': entry.value.id,
              'number': '${_buildingNumber(entry.key, entry.value)}',
            },
          },
      ],
    });
  }

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campus?.id != widget.campus?.id) {
      final campus = widget.campus;
      if (campus != null) {
        // Se aplica el nuevo límite antes de mover la cámara.
        fitToCampus(campus);
      }
    }
    _refreshSources();
  }

  CoordinateBounds _boundsForCampus(Campus campus) {
    final area = areaForCampus(campus);
    return CoordinateBounds(
      southwest: _position(
        campus.longitude - area.longitudeSpan / 2,
        campus.latitude - area.latitudeSpan / 2,
      ),
      northeast: _position(
        campus.longitude + area.longitudeSpan / 2,
        campus.latitude + area.latitudeSpan / 2,
      ),
      infiniteBounds: false,
    );
  }

  Future<void> _applyBoundsAndMove(Campus campus) async {
    final map = _map;
    if (map == null) return;
    final revision = ++_boundsRevision;
    final area = areaForCampus(campus);
    try {
      await map.setBounds(
        CameraBoundsOptions(
          bounds: _boundsForCampus(campus),
          minZoom: area.minZoom,
          maxZoom: area.maxZoom,
          minPitch: 0,
          maxPitch: 60,
        ),
      );
      if (!mounted ||
          revision != _boundsRevision ||
          widget.campus?.id != campus.id)
        return;
      _viewportController.moveTo(
        CameraViewportState(
          center: _position(campus.longitude, campus.latitude),
          zoom: area.initialZoom,
          pitch: area.pitch,
          bearing: area.bearing,
        ),
        transition: EasingViewportTransition(
          duration: const Duration(milliseconds: 850),
        ),
      );
    } catch (error) {
      debugPrint('[UCT Mapbox] No se pudieron aplicar límites: $error');
    }
  }

  /// Puede ser invocado por el botón "Centrar campus" del orquestador.
  void fitToCampus(Campus campus) {
    _applyBoundsAndMove(campus);
  }

  void _onMapCreated(MapboxMap map) {
    _map = map;
    final campus = widget.campus;
    if (campus != null) _applyBoundsAndMove(campus);
  }

  Future<void> _onStyleLoaded() async {
    final map = _map;
    if (map == null) return;
    _styleReady = false;
    final revision = ++_revision;
    try {
      // Personalización de Mapbox Standard con identidad visual UCT.
      // Se aplica al cargar el estilo, antes de crear las capas GeoJSON.
      // Los edificios del mapa base permanecen en 3D.
      try {
        await map.style.setStyleImportConfigProperties('basemap', {
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
        debugPrint('[UCT Mapbox] Estilo UCT aplicado');
      } catch (error) {
        // Si una propiedad no es compatible, el mapa y sus marcadores siguen.
        debugPrint('[UCT Mapbox] No se pudo aplicar estilo UCT: $error');
      }

      final campusSource = GeoJsonSource(
        id: _campusSourceId,
        data: _campusGeoJson(),
      );
      final buildingSource = GeoJsonSource(
        id: _buildingSourceId,
        data: _buildingGeoJson(),
      );
      await map.addSource(campusSource);
      await map.addSource(buildingSource);

      await map.addLayer(
        CircleLayer(
          id: _campusLayerId,
          sourceId: _campusSourceId,
          circleRadius: 22,
          circleColor: _blue,
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 3,
        ),
      );
      await map.addLayer(
        SymbolLayer(
          id: _campusTextLayerId,
          sourceId: _campusSourceId,
          textField: '🎓',
          textSize: 21,
          textAllowOverlap: true,
        ),
      );
      await map.addLayer(
        CircleLayer(
          id: _buildingCircleLayerId,
          sourceId: _buildingSourceId,
          circleRadius: 19,
          circleColor: 0xFFFFFFFF,
          circleStrokeColor: _blue,
          circleStrokeWidth: 3,
        ),
      );
      await map.addLayer(
        SymbolLayer(
          id: _buildingTextLayerId,
          sourceId: _buildingSourceId,
          textFieldExpression: ['get', 'number'],
          textColor: _blue,
          textSize: 16,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
      );

      map.addInteraction(
        TapInteraction(FeaturesetDescriptor(layerId: _buildingCircleLayerId), (
          feature,
          context,
        ) {
          final id = feature.properties['buildingId']?.toString();
          if (id == null) return;
          final index = widget.buildings.indexWhere((b) => b.id == id);
          if (index == -1) return;
          final building = widget.buildings[index];
          widget.onBuildingTap(_buildingNumber(index, building), building);
        }),
        interactionID: 'uct-building-tap',
      );
      // El numero se dibuja encima del circulo; ambas capas son pulsables.
      map.addInteraction(
        TapInteraction(FeaturesetDescriptor(layerId: _buildingTextLayerId), (
          feature,
          context,
        ) {
          final id = feature.properties['buildingId']?.toString();
          if (id == null) return;
          final index = widget.buildings.indexWhere((b) => b.id == id);
          if (index == -1) return;
          final building = widget.buildings[index];
          widget.onBuildingTap(_buildingNumber(index, building), building);
        }),
        interactionID: 'uct-building-label-tap',
      );
      map.addInteraction(
        TapInteraction(FeaturesetDescriptor(layerId: _campusLayerId), (
          feature,
          context,
        ) {
          final campus = widget.campus;
          if (campus != null) widget.onCampusTap(campus);
        }),
        interactionID: 'uct-campus-tap',
      );
      map.addInteraction(
        TapInteraction(FeaturesetDescriptor(layerId: _campusTextLayerId), (
          feature,
          context,
        ) {
          final campus = widget.campus;
          if (campus != null) widget.onCampusTap(campus);
        }),
        interactionID: 'uct-campus-label-tap',
      );

      if (!mounted || revision != _revision) return;
      _campusSource = campusSource;
      _buildingSource = buildingSource;
      _styleReady = true;
      await _refreshSources();
    } catch (error) {
      debugPrint('[UCT Mapbox] No se pudieron crear marcadores: $error');
    }
  }

  Future<void> _refreshSources() async {
    if (!_styleReady) return;
    try {
      await _campusSource?.updateGeoJSON(_campusGeoJson());
      await _buildingSource?.updateGeoJSON(_buildingGeoJson());
    } catch (error) {
      debugPrint('[UCT Mapbox] Error actualizando marcadores: $error');
    }
  }

  @override
  void dispose() {
    _revision++;
    _boundsRevision++;
    _viewportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campus = widget.campus;
    final area = campus == null ? null : areaForCampus(campus);
    return MapWidget(
      styleUri: MapboxStyles.STANDARD,
      viewportController: _viewportController,
      viewport: CameraViewportState(
        center: campus == null
            ? _position(-72.5904, -38.7359)
            : _position(campus.longitude, campus.latitude),
        zoom: area?.initialZoom ?? 16.5,
        pitch: area?.pitch ?? 50,
        bearing: area?.bearing ?? -20,
      ),
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: (_) => _onStyleLoaded(),
    );
  }
}
