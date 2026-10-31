import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/network/api_client_provider.dart';
import '../../../../domain/entities/building.dart';
import '../../../../data/models/campus_location_dto.dart';
import '../../../../data/datasources/campus_remote_ds.dart';
import '../../../../domain/entities/category.dart';

/// Resultado de busqueda: la ubicacion de una sala es la de su edificio.
class CampusSearchResult {
  const CampusSearchResult({
    this.building,
    this.roomCode,
    this.roomFloor,
    this.categoryId,
    this.structure,
  });

  final Building? building;
  final String? roomCode;
  final int? roomFloor;
  final String? categoryId;
  final StructureLocationDto? structure;
}

/// Busca salas en Campus Service y edificios entre los ya cargados.
/// Se limita a los edificios del campus actualmente seleccionado.
class CampusSearchSheet extends StatefulWidget {
  const CampusSearchSheet({
    super.key,
    required this.buildings,
    required this.structures,
    this.onSelected,
    this.embedded = false,
    this.searchRooms,
    this.loadCategories,
    this.campusSelector,
    this.onProfessors,
  });

  final List<Building> buildings;
  final List<StructureLocationDto> structures;
  final ValueChanged<CampusSearchResult>? onSelected;
  final bool embedded;
  final Future<List<dynamic>> Function(String)? searchRooms;
  final Future<List<Category>> Function()? loadCategories;
  final Widget? campusSelector;
  final VoidCallback? onProfessors;

  @override
  State<CampusSearchSheet> createState() => _CampusSearchSheetState();
}

class _CampusSearchSheetState extends State<CampusSearchSheet> {
  static const _blue = Color(0xFF003865);
  static const _yellow = Color(0xFFEAA221);

  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  List<CampusSearchResult> _results = [];
  int _requestId = 0;
  String _type = 'Todos';
  String? _category;
  bool _searched = false;
  Timer? _debounce;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    (widget.loadCategories?.call() ?? CampusRemoteDataSource().getCategories())
        .then((categories) {
          if (mounted) setState(() => _categories = categories);
        })
        .catchError((_) {});
  }

  @override
  void didUpdateWidget(covariant CampusSearchSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buildings != widget.buildings ||
        oldWidget.structures != widget.structures) {
      _requestId++;
      _results = [];
      _loading = false;
      if (_controller.text.trim().isNotEmpty) _search();
    }
  }

  @override
  void dispose() {
    _requestId++;
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final term = _controller.text.trim();
    final request = ++_requestId;
    if (term.isEmpty) {
      setState(() {
        _error = null;
        _results = [];
        _searched = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _searched = true;
    });

    final matches = widget.buildings
        .where(
          (building) =>
              building.name.toLowerCase().contains(term.toLowerCase()),
        )
        .map((building) => CampusSearchResult(building: building))
        .toList();

    matches.addAll(
      widget.structures
          .where(
            (s) =>
                s.name.toLowerCase().contains(term.toLowerCase()) ||
                s.categoryName.toLowerCase().contains(term.toLowerCase()),
          )
          .map((s) => CampusSearchResult(structure: s)),
    );

    try {
      final response =
          await (widget.searchRooms?.call(term) ??
              ApiClientProvider.apiClient.getJson<List<dynamic>>(
                '/api/campus/rooms/search',
                queryParameters: {'term': term},
              ));

      final byId = {
        for (final building in widget.buildings)
          building.id.toLowerCase(): building,
      };
      final seen = <String>{};
      for (final item in response) {
        if (item is! Map) continue;
        final room = item.cast<String, dynamic>();
        final buildingId = (room['buildingId'] ?? room['BuildingId'] ?? '')
            .toString()
            .toLowerCase();
        final building = byId[buildingId];
        if (building == null) continue; // Ignora salas de otros campus.
        final roomCode = (room['name'] ?? room['Name'] ?? '').toString();
        final roomNumber = (room['number'] ?? room['Number'] ?? '').toString();
        if (!roomCode.toLowerCase().contains(term.toLowerCase()) &&
            !roomNumber.toLowerCase().contains(term.toLowerCase()))
          continue;
        if (seen.add('$buildingId:$roomCode')) {
          matches.add(
            CampusSearchResult(
              building: building,
              roomCode: roomCode,
              roomFloor: (room['floor'] as num?)?.toInt(),
              categoryId: (room['categoryId'] ?? '').toString(),
            ),
          );
        }
      }
      if (!mounted || request != _requestId) return;
      setState(() => _results = matches);
    } catch (error) {
      if (!mounted || request != _requestId) return;
      setState(() {
        _results = matches;
        _error = 'No se pudieron buscar salas. Se muestran los resultados disponibles.';
      });
      debugPrint('[UCT Search] $error');
    } finally {
      if (mounted && request == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final categories = {
      for (final c in _categories) c.id: c.name,
      for (final s in widget.structures)
        if (s.categoryName.isNotEmpty) s.categoryId: s.categoryName,
    };
    final results = _results.where((r) {
      if (_type == 'Edificios' && (r.structure != null || r.roomCode != null))
        return false;
      if (_type == 'Salas' && r.roomCode == null) return false;
      if (_type == 'Servicios' && r.structure == null) return false;
      return _category == null ||
          r.structure?.categoryId == _category ||
          r.categoryId == _category;
    }).toList();
    if (widget.embedded) return _buildSearchPage(results);
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: widget.embedded
              ? null
              : MediaQuery.of(context).size.height * 0.64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Buscar edificio, sala o servicio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _blue,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  autofocus: !widget.embedded,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    _requestId++;
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 300),
                      _search,
                    );
                  },
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Ej.: CJP07_301 o Ricardo Ferrando',
                    prefixIcon: const Icon(Icons.search, color: _blue),
                    suffixIcon: IconButton(
                      tooltip: 'Buscar',
                      icon: const Icon(Icons.arrow_forward, color: _blue),
                      onPressed: _search,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final type in [
                      'Todos',
                      'Edificios',
                      'Salas',
                      'Servicios',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: _type == type,
                          onSelected: (_) => setState(() {
                            _type = type;
                            _category = null;
                          }),
                        ),
                      ),
                    for (final category in categories.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category.value),
                          selected: _category == category.key,
                          onSelected: (selected) => setState(
                            () => _category = selected ? category.key : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_loading) const LinearProgressIndicator(color: _yellow),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: _search,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: results.isEmpty && !_loading
                    ? Center(
                        child: Text(
                          _searched
                              ? 'No se encontraron resultados.'
                              : 'Escribe un nombre o código para buscar.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          return ListTile(
                            leading: Icon(
                              result.structure != null
                                  ? Icons.place
                                  : result.roomCode == null
                                  ? Icons.apartment
                                  : Icons.meeting_room,
                              color: _blue,
                            ),
                            title: Text(
                              result.structure?.name ??
                                  result.roomCode ??
                                  result.building!.name,
                            ),
                            subtitle: Text(
                              result.structure != null
                                  ? result.structure!.categoryName
                                  : result.roomCode == null
                                  ? 'Edificio'
                                  : 'Edificio: ${result.building!.name}',
                            ),
                            trailing: const Icon(
                              Icons.location_on,
                              color: _yellow,
                            ),
                            onTap: () => widget.onSelected != null
                                ? widget.onSelected!(result)
                                : Navigator.of(context).pop(result),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchPage(List<CampusSearchResult> results) {
    final categories = [
      ('Edificios', Icons.apartment_rounded, Colors.indigo),
      ('Salas', Icons.meeting_room_rounded, Colors.teal),
      ('Profesores', Icons.school_rounded, Colors.blue),
      (
        'Servicios',
        Icons.miscellaneous_services_rounded,
        Colors.amber.shade800,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu, color: _blue),
                  tooltip: 'Categorías',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onChanged: (_) {
                      setState(() {});
                      _requestId++;
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 300),
                        _search,
                      );
                    },
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Buscar edificio, sala, servicio...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _controller.clear();
                      _search();
                    },
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
        if (widget.campusSelector != null) widget.campusSelector!,
        const SizedBox(height: 18),
        const Text(
          'Categorías',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            for (final category in categories)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: _type == category.$1
                        ? _blue
                        : const Color(0xFFE3E7EE),
                    width: _type == category.$1 ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (category.$1 == 'Profesores') {
                      widget.onProfessors?.call();
                      return;
                    }
                    if (_type == category.$1) {
                      _requestId++;
                      _debounce?.cancel();
                      setState(() {
                        _type = 'Todos';
                        _category = null;
                        _results = [];
                        _searched = false;
                        _loading = false;
                        _error = null;
                      });
                      return;
                    }
                    setState(() {
                      _type = category.$1;
                      _category = null;
                    });
                    if (_controller.text.trim().isEmpty) {
                      _searchAll();
                    } else {
                      _search();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: category.$3.withValues(alpha: 0.12),
                          child: Icon(
                            category.$2,
                            color: category.$3,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            category.$1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _type == category.$1
                                  ? _blue
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_categories.isNotEmpty &&
            (_type == 'Salas' || _type == 'Servicios'))
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: _category == category.id,
                      onSelected: (selected) => setState(
                        () => _category = selected ? category.id : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(color: _yellow),
          ),
        if (_error != null)
          Row(
            children: [
              Expanded(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: _controller.text.trim().isEmpty
                    ? _searchAll
                    : _search,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        if (_searched) ...[
          const SizedBox(height: 20),
          const Text(
            'Resultados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (results.isEmpty && !_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No se encontraron resultados.'),
            ),
          for (final result in results)
            Card(
              child: ListTile(
                leading: Icon(
                  result.structure != null
                      ? Icons.place
                      : result.roomCode == null
                      ? Icons.apartment
                      : Icons.meeting_room,
                  color: _blue,
                ),
                title: Text(
                  result.structure?.name ??
                      result.roomCode ??
                      result.building!.name,
                ),
                subtitle: Text(
                  result.structure?.categoryName ??
                      (result.roomCode == null
                          ? 'Edificio'
                          : 'Edificio: ${result.building!.name}'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => widget.onSelected?.call(result),
              ),
            ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Profesores Destacados',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onProfessors,
              child: const Text('Ver todos'),
            ),
          ],
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.school)),
            title: const Text('Directorio de profesores'),
            subtitle: const Text('Consulta el directorio y la disponibilidad'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onProfessors,
          ),
        ),
      ],
    );
  }

  void _searchAll() {
    if (_controller.text.trim().isNotEmpty) {
      _search();
      return;
    }
    final request = ++_requestId;
    setState(() {
      _searched = true;
      _loading = true;
      _error = null;
    });
    final matches = <CampusSearchResult>[
      for (final b in widget.buildings) CampusSearchResult(building: b),
      for (final s in widget.structures) CampusSearchResult(structure: s),
    ];
    ApiClientProvider.apiClient
        .getJson<List<dynamic>>('/api/campus/rooms')
        .then((rooms) {
          final buildings = {
            for (final b in widget.buildings) b.id.toLowerCase(): b,
          };
          for (final item in rooms.whereType<Map<String, dynamic>>()) {
            final building =
                buildings[(item['buildingId'] ?? '').toString().toLowerCase()];
            if (building != null)
              matches.add(
                CampusSearchResult(
                  building: building,
                  roomCode: (item['name'] ?? '').toString(),
                  roomFloor: (item['floor'] as num?)?.toInt(),
                  categoryId: (item['categoryId'] ?? '').toString(),
                ),
              );
          }
          if (mounted && request == _requestId)
            setState(() {
              _results = matches;
              _loading = false;
            });
        })
        .catchError((_) {
          if (mounted && request == _requestId)
            setState(() {
              _results = matches;
              _loading = false;
              _error = 'No se pudieron cargar las salas.';
            });
        });
  }
}
