import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../data/models/campus_location_dto.dart';
import '../../../domain/entities/app_permission.dart';
import '../login/session_required_view.dart';

/// Selector explícito: el administrador centra el mapa y confirma la nueva ubicación.
class CampusLocationPickerScreen extends StatefulWidget {
  const CampusLocationPickerScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.title,
  });

  final double latitude;
  final double longitude;
  final String title;

  @override
  State<CampusLocationPickerScreen> createState() =>
      _CampusLocationPickerScreenState();
}

class _CampusLocationPickerScreenState
    extends State<CampusLocationPickerScreen> {
  MapboxMap? _map;
  bool _busy = false;

  Future<void> _confirm() async {
    final map = _map;
    if (map == null || _busy) return;
    setState(() => _busy = true);
    try {
      final center = (await map.getCameraState()).center.coordinates;
      if (mounted) {
        Navigator.pop(
          context,
          CampusCoordinateDto(
            latitude: center.lat.toDouble(),
            longitude: center.lng.toDouble(),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el centro del mapa.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.manageUsers,
    builder: (_) => Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          MapWidget(
            styleUri: MapboxStyles.STANDARD,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(widget.longitude, widget.latitude),
              ),
              zoom: 18,
              pitch: 0,
              bearing: 0,
            ),
            onMapCreated: (map) => _map = map,
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.location_pin,
                  color: Color(0xFFB42318),
                  size: 46,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Mueve el mapa hasta la ubicación y confirma el punto bajo el marcador.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: FilledButton.icon(
              onPressed: _busy ? null : _confirm,
              icon: const Icon(Icons.my_location),
              label: Text(
                _busy ? 'Leyendo ubicación…' : 'Usar ubicación del marcador',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
