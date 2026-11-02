import '../../../data/models/campus_location_dto.dart';

import 'package:flutter/material.dart';

import '../../../application/navigation/campus_location.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../domain/entities/campus_map_target.dart';
import '../../../domain/repositories/campus_repository.dart';
import 'widgets/campus_map_view.dart';

class CampusLocationScreen extends StatefulWidget {
  const CampusLocationScreen({
    super.key,
    required this.target,
    this.repository,
  });
  final CampusMapTarget target;
  final CampusRepository? repository;
  @override
  State<CampusLocationScreen> createState() => _CampusLocationScreenState();
}

class _CampusLocationScreenState extends State<CampusLocationScreen> {
  late Future<CampusLocation> _location = _load();
  Future<CampusLocation> _load() async {
    try {
      return await resolveCampusLocation(
        widget.repository ?? CampusRemoteDataSource(),
        widget.target,
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) throw LocationUnavailable();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ubicación del espacio'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
    ),
    body: FutureBuilder<CampusLocation>(
      future: _location,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    color: AppColors.uctBlue,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error is LocationUnavailable
                        ? 'Este espacio no tiene una ubicación cartográfica verificable.'
                        : 'No se pudo consultar la ubicación. Revisa tu conexión e inténtalo de nuevo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() {
                      _location = _load();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        final location = snapshot.data!;
        return Column(
          children: [
            Expanded(
              child: CampusMapView(
                campus: location.campus,
                focusLocation:
                    location.structure?.location ??
                    CampusCoordinateDto(
                      latitude: location.building!.latitude,
                      longitude: location.building!.longitude,
                    ),
                buildings: [if (location.building != null) location.building!],
                structures: [
                  if (location.structure != null) location.structure!,
                ],
                onReady: (map) {
                  if (location.structure != null) {
                    map.focusOnStructure(location.structure!);
                  } else {
                    map.focusOnBuilding(location.building!);
                  }
                },
                onCampusTap: (campus) =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(campus.name))),
                onBuildingTap: (_, building) =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(building.name))),
                onStructureTap: (structure) =>
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(structure.name))),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.uctBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.uctBlue,
                                ),
                          ),
                          Text(
                            location.room == null
                                ? location.campus.name
                                : '${location.building!.name} · Piso ${location.room!.floor}',
                          ),
                          if (location.room != null)
                            const Text(
                              'Se muestra el edificio de la sala, sin ubicación interior.',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
