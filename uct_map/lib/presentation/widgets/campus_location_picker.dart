import 'package:flutter/material.dart';

import '../../data/datasources/campus_remote_ds.dart';
import '../../domain/entities/campus.dart';
import '../../domain/repositories/campus_repository.dart';

/// Selecciona una ubicación existente, conservando su ID para Incident.
class CampusLocationPicker extends StatefulWidget {
  const CampusLocationPicker({
    super.key,
    required this.controller,
    this.repository,
    this.initialCampusId,
  });
  final TextEditingController controller;
  final CampusRepository? repository;
  final String? initialCampusId;

  @override
  State<CampusLocationPicker> createState() => _CampusLocationPickerState();
}

class _CampusLocationPickerState extends State<CampusLocationPicker> {
  late final CampusRepository _repository =
      widget.repository ?? CampusRemoteDataSource();
  List<Campus>? _campuses;
  Map<String, String> _locations = {};
  String? _campus;
  bool _loading = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _loadCampuses();
  }

  @override
  void didUpdateWidget(covariant CampusLocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    final targetId = widget.controller.text.trim();
    if (targetId.isEmpty) return;
    if (_locations.containsKey(targetId)) {
      if (mounted) setState(() {});
      return;
    }
    if (_campuses != null && !_loading) {
      _resolveCampusForLocation(targetId);
    }
  }

  Future<void> _resolveCampusForLocation(String locationId) async {
    final campuses = _campuses;
    if (campuses == null || campuses.isEmpty) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      for (final campus in campuses) {
        final result = await Future.wait([
          _repository.getBuildings(campus.id),
          _repository.getStructures(campus.id),
        ]);
        if (!mounted || request != _request) return;
        final buildings = result[0] as List;
        final structures = result[1] as List;
        final locations = {
          for (final b in buildings) b.id as String: '${b.name} (edificio)',
          for (final s in structures) s.id as String: '${s.name}',
        };
        if (locations.containsKey(locationId)) {
          setState(() {
            _campus = campus.id;
            _locations = locations;
            _loading = false;
          });
          return;
        }
      }
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadCampuses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final campuses = await _repository.getCampuses();
      if (!mounted) return;
      setState(() {
        _campuses = campuses;
        _loading = false;
      });
      if (widget.initialCampusId != null &&
          campuses.any((c) => c.id == widget.initialCampusId)) {
        await _selectCampus(widget.initialCampusId, preserveSelection: true);
      } else if (widget.controller.text.trim().isNotEmpty) {
        await _resolveCampusForLocation(widget.controller.text.trim());
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'No se pudieron cargar los campus.';
        });
    }
  }

  Future<void> _selectCampus(
    String? campus, {
    bool preserveSelection = false,
  }) async {
    if (campus == null) return;
    final request = ++_request;
    setState(() {
      _campus = campus;
      _locations = {};
      if (!preserveSelection) widget.controller.clear();
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        _repository.getBuildings(campus),
        _repository.getStructures(campus),
      ]);
      if (!mounted || request != _request) return;
      final buildings = result[0] as List;
      final structures = result[1] as List;
      setState(() {
        _locations = {
          for (final b in buildings) b.id as String: '${b.name} (edificio)',
          for (final s in structures) s.id as String: '${s.name}',
        };
        if (!_locations.containsKey(widget.controller.text))
          widget.controller.clear();
        _loading = false;
      });
    } catch (_) {
      if (mounted && request == _request)
        setState(() {
          _loading = false;
          _error = 'No se pudieron cargar las ubicaciones.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<String>(
        initialValue: _campus,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Campus'),
        items: (_campuses ?? [])
            .map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _loading ? null : _selectCampus,
        validator: (_) =>
            _campus == null ||
                _loading ||
                !_locations.containsKey(widget.controller.text)
            ? 'Selecciona un campus y una ubicación.'
            : null,
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null)
        Row(
          children: [
            Expanded(child: Text(_error!)),
            TextButton(
              onPressed: () =>
                  _campus == null ? _loadCampuses() : _selectCampus(_campus),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      if (_campus != null && !_loading && _error == null)
        DropdownButtonFormField<String>(
          initialValue: _locations.containsKey(widget.controller.text)
              ? widget.controller.text
              : null,
          isExpanded: true,
          key: ValueKey(_campus),
          decoration: const InputDecoration(labelText: 'Ubicación'),
          items: _locations.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) =>
              setState(() => widget.controller.text = value ?? ''),
          validator: (value) =>
              value == null ? 'Selecciona una ubicación.' : null,
        ),
    ],
  );
}
