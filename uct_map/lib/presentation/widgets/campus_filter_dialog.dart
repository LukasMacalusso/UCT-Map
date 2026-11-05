import 'package:flutter/material.dart';

import '../../data/datasources/campus_remote_ds.dart';
import '../../domain/entities/campus.dart';
import '../../domain/repositories/campus_repository.dart';

class CampusFilterSelection {
  const CampusFilterSelection(this.label, this.locationIds, this.locationId);
  final String label;
  final Set<String> locationIds;
  final String? locationId;
}

Future<CampusFilterSelection?> showCampusFilterDialog(
  BuildContext context, {
  CampusRepository? repository,
}) => showDialog<CampusFilterSelection>(
  context: context,
  builder: (_) => _CampusFilterDialog(repository: repository),
);

class _CampusFilterDialog extends StatefulWidget {
  const _CampusFilterDialog({this.repository});
  final CampusRepository? repository;
  @override
  State<_CampusFilterDialog> createState() => _CampusFilterDialogState();
}

class _CampusFilterDialogState extends State<_CampusFilterDialog> {
  late final CampusRepository _repository =
      widget.repository ?? CampusRemoteDataSource();
  List<Campus> _campuses = [];
  Campus? _selected;
  Map<String, String> _places = {};
  String? _place;
  bool _loading = true;
  String? _error;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repository.getCampuses();
      if (mounted)
        setState(() {
          _campuses = result;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'No se pudieron cargar los campus.';
        });
    }
  }

  Future<void> _choose(String? id) async {
    if (id == null) return;
    final version = ++_version;
    setState(() {
      _selected = _campuses.firstWhere((c) => c.id == id);
      _place = null;
      _places = {};
      _loading = true;
      _error = null;
    });
    try {
      final buildings = await _repository.getBuildings(id);
      final structures = await _repository.getStructures(id);
      if (!mounted || version != _version) return;
      setState(() {
        _places = {
          for (final b in buildings) b.id: b.name,
          for (final s in structures) s.id: s.name,
        };
        _loading = false;
      });
    } catch (_) {
      if (mounted && version == _version)
        setState(() {
          _loading = false;
          _error = 'No se pudieron cargar las ubicaciones.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Filtrar ubicación'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
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
          onChanged: _loading ? null : _choose,
        ),
        if (_selected != null && !_loading && _error == null)
          DropdownButtonFormField<String>(
            initialValue: _place,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Lugar'),
            hint: const Text('Todos los lugares'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Todos los lugares'),
              ),
              ..._places.entries.map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _place = value),
          ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Column(
            children: [
              Text(_error!),
              TextButton(
                onPressed: () => _selected == null
                    ? _loadCampuses()
                    : _choose(_selected!.id),
                child: const Text('Reintentar'),
              ),
            ],
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _selected == null || _loading || _error != null
            ? null
            : () => Navigator.pop(
                context,
                CampusFilterSelection(
                  _place == null
                      ? _selected!.name
                      : '${_selected!.name} · ${_places[_place]}',
                  _places.keys.toSet(),
                  _place,
                ),
              ),
        child: const Text('Aplicar'),
      ),
    ],
  );
}
