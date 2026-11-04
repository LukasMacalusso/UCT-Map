import 'package:flutter/material.dart';
import '../../data/datasources/campus_remote_ds.dart';

class CampusLocationLabel extends StatefulWidget {
  const CampusLocationLabel({super.key, required this.id, this.style});
  final String id;
  final TextStyle? style;
  @override
  State<CampusLocationLabel> createState() => _CampusLocationLabelState();
}

class _CampusLocationLabelState extends State<CampusLocationLabel> {
  late Future<String> _label = _resolve();
  @override
  void didUpdateWidget(covariant CampusLocationLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _label = _resolve();
  }

  Future<String> _resolve() async {
    final campus = CampusRemoteDataSource();
    Future<String> display(String name, String campusId) async {
      try { return '$name · ${(await campus.getCampusById(campusId)).name}'; }
      catch (_) { return name; }
    }
    try {
      final place = await campus.getStructureById(widget.id);
      return await display(place.name, place.campusId);
    } catch (_) {
      try {
        final place = await campus.getBuildingById(widget.id);
        return await display(place.name, place.campusId);
      } catch (_) { return 'Ubicación no disponible'; }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
    future: _label,
    builder: (context, snapshot) => Text(snapshot.data ?? 'Cargando ubicación…', style: widget.style, overflow: TextOverflow.ellipsis),
  );
}
