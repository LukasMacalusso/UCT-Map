import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../data/models/campus_location_dto.dart';
import '../../../domain/entities/building.dart';
import '../../../domain/entities/campus.dart';
import '../map/widgets/campus_search_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.onExploreMap,
    this.selectedCampus,
    this.onResult,
  });
  final VoidCallback onExploreMap;
  final ValueNotifier<Campus?>? selectedCampus;
  final ValueChanged<CampusSearchResult>? onResult;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _source = CampusRemoteDataSource();
  List<Campus> _campuses = [];
  List<Building> _buildings = [];
  List<StructureLocationDto> _structures = [];
  String? _error;
  bool _loading = true;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    widget.selectedCampus?.addListener(_campusChanged);
    ApiClientProvider.session.addListener(_sessionChanged);
    ApiClientProvider.session.ready.then((_) {
      if (mounted) _loadCampuses();
    });
  }

  @override
  void dispose() {
    _request++;
    ApiClientProvider.session.removeListener(_sessionChanged);
    widget.selectedCampus?.removeListener(_campusChanged);
    super.dispose();
  }

  void _sessionChanged() {
    if (mounted) _loadCampuses();
  }

  Future<void> _loadCampuses() async {
    try {
      final campuses = await _source.getCampuses();
      if (!mounted) return;
      setState(() => _campuses = campuses);
      final selected =
          widget.selectedCampus?.value ??
          (campuses.isEmpty ? null : campuses.first);
      if (selected == null) {
        setState(() {
          _loading = false;
          _error = 'No hay campus disponibles.';
        });
      } else {
        if (widget.selectedCampus != null &&
            widget.selectedCampus!.value == null) {
          widget.selectedCampus!.value = selected;
        } else {
          _load(selected);
        }
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error =
              'No se pudieron cargar los campus. Revisa tu sesión y conexión.';
        });
    }
  }

  void _campusChanged() {
    final campus = widget.selectedCampus?.value;
    if (campus != null) _load(campus);
  }

  Future<void> _load(Campus campus) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _buildings = [];
      _structures = [];
    });
    var failed = false;
    final results = await Future.wait([
      _source.getBuildings(campus.id).then<Object>((v) => v).catchError((_) {
        failed = true;
        return <Building>[];
      }),
      _source
          .getStructureLocations(campusId: campus.id)
          .then<Object>((v) => v)
          .catchError((_) {
            failed = true;
            return <StructureLocationDto>[];
          }),
    ]);
    if (!mounted || request != _request) return;
    setState(() {
      _buildings = results[0] as List<Building>;
      _structures = results[1] as List<StructureLocationDto>;
      _loading = false;
      _error = failed ? 'Algunos datos no se pudieron cargar.' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedCampus?.value;
    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        if (_error != null)
          Row(
            children: [
              Expanded(child: Text(_error!)),
              TextButton(
                onPressed: _loadCampuses,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        Expanded(
          child: CampusSearchSheet(
            key: ValueKey(selected?.id),
            buildings: _buildings,
            structures: _structures,
            embedded: true,
            campusSelector: DropdownButton<Campus>(
              isExpanded: true,
              hint: const Text('Selecciona un campus'),
              value: _campuses.where((c) => c.id == selected?.id).firstOrNull,
              items: _campuses
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (campus) {
                if (campus == null) return;
                if (widget.selectedCampus != null) {
                  widget.selectedCampus!.value = campus;
                } else {
                  _load(campus);
                }
              },
            ),
            onProfessors: () =>
                Navigator.pushNamed(context, AppRoutes.professors),
            onSelected: (result) {
              if (widget.onResult != null) {
                widget.onResult!(result);
              } else {
                widget.onExploreMap();
              }
            },
          ),
        ),
      ],
    );
  }
}
