import '../../core/network/api_exception.dart';

import 'package:flutter/material.dart';

import '../../data/datasources/campus_remote_ds.dart';
import '../../domain/repositories/campus_repository.dart';

class CampusLocationLabel extends StatefulWidget {
  const CampusLocationLabel({
    super.key,
    required this.id,
    this.style,
    this.repository,
  });
  final String id;
  final TextStyle? style;
  final CampusRepository? repository;
  @override
  State<CampusLocationLabel> createState() => _CampusLocationLabelState();
}

class _CampusLocationLabelState extends State<CampusLocationLabel> {
  late Future<String> _label = _resolve();
  @override
  void didUpdateWidget(covariant CampusLocationLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.repository != widget.repository) {
      _label = _resolve();
    }
  }

  Future<String> _resolve() async {
    final campus = widget.repository ?? CampusRemoteDataSource();
    Future<String> display(String name, String campusId) async {
      try {
        return '$name · ${(await campus.getCampusById(campusId)).name}';
      } catch (_) {
        return name;
      }
    }

    try {
      final place = await campus.getStructureById(widget.id);
      return await display(place.name, place.campusId);
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      try {
        final place = await campus.getBuildingById(widget.id);
        return await display(place.name, place.campusId);
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
        return 'Ubicación no disponible';
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _label,
    builder: (context, snapshot) => Text(
      snapshot.hasError
          ? 'No se pudo cargar la ubicación'
          : snapshot.data ?? 'Cargando ubicación…',
      style: widget.style,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
