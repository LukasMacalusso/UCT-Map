import '../../../application/directory/filter_professors.dart';
import '../../../domain/entities/campus.dart';

import 'package:flutter/material.dart';

import '../../../application/session/session_controller.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/schedule_remote_ds.dart';
import '../../../data/datasources/campus_remote_ds.dart';
import '../../../domain/repositories/campus_repository.dart';
import '../../../domain/entities/professor.dart';
import '../../../domain/repositories/schedule_repository.dart';
import 'professor_detail_screen.dart';

/// Pantalla Directorio de Profesores conectada al Schedule Service (ms.svg).
class ProfessorsScreen extends StatefulWidget {
  const ProfessorsScreen({
    super.key,
    this.onNavigateToTab,
    this.scheduleRepository,
    this.campusRepository,
  });

  final Function(int)? onNavigateToTab;
  final ScheduleRepository? scheduleRepository;
  final CampusRepository? campusRepository;

  @override
  State<ProfessorsScreen> createState() => _ProfessorsScreenState();
}

class _ProfessorsScreenState extends State<ProfessorsScreen> {
  late final ScheduleRepository _repository;
  late final CampusRepository _campus =
      widget.campusRepository ?? CampusRemoteDataSource();
  List<Professor> _professors = [];
  Map<String, String> _locations = {};
  bool _locationError = false;
  String? _loadedToken;
  int _loadVersion = 0;
  bool _loading = true;
  String _searchQuery = '';
  String? _error;
  List<Campus> _campuses = [];
  Map<String, String> _campusByLocation = {};
  String? _campusFilter;
  String? _locationFilter;
  int? _dayFilter;
  bool? _hoursFilter;
  bool _campusError = false;
  int _page = 0;

  SessionController get _session => ApiClientProvider.session;
  @override
  void initState() {
    super.initState();
    _repository = widget.scheduleRepository ?? ScheduleRemoteDataSource();
    _loadedToken = _session.token;
    _session.addListener(_sessionChanged);
    _loadProfessors();
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    super.dispose();
  }

  void _sessionChanged() {
    if (_loadedToken == _session.token) return;
    _loadedToken = _session.token;
    _loadVersion++;
    setState(() {
      _professors = [];
      _locations = {};
      _campuses = [];
      _campusByLocation = {};
      _campusFilter = null;
      _locationFilter = null;
      _dayFilter = null;
      _hoursFilter = null;
      _page = 0;
      _locationError = false;
      _error = null;
      _loading = _session.isAuthenticated;
    });
    if (_session.isAuthenticated) _loadProfessors();
  }

  Future<void> _loadProfessors() async {
    final version = ++_loadVersion;
    final token = _session.token;
    bool current() =>
        mounted && version == _loadVersion && _session.token == token;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repository.getProfessors();
      if (!current()) return;
      final locations = <String, String>{};
      final campusByLocation = <String, String>{};
      var locationError = false;
      final ids = list
          .expand((p) => p.officeHours)
          .map((h) => h.structureRefId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();
      for (final id in ids) {
        if (!current()) return;
        try {
          final structure = await _campus.getStructureById(id);
          if (!current()) return;
          if (structure.id == id && structure.name.trim().isNotEmpty) {
            locations[id] = structure.name;
            campusByLocation[id] = structure.campusId;
          } else {
            locationError = true;
          }
        } catch (_) {
          if (!current()) return;
          locationError = true;
        }
      }
      List<Campus> campuses = [];
      var campusError = false;
      try {
        campuses = await _campus.getCampuses();
      } catch (_) {
        campusError = true;
      }
      if (current()) {
        setState(() {
          _campuses = campuses;
          if (!campuses.any((c) => c.id == _campusFilter)) _campusFilter = null;
          if (!locations.containsKey(_locationFilter)) _locationFilter = null;
          _campusByLocation = campusByLocation;
          _campusError = campusError;
          _professors = list;
          _locations = locations;
          _locationError = locationError;
          _loading = false;
        });
      }
    } catch (_) {
      if (current()) {
        setState(() {
          _professors = [];
          _locations = {};
          _loading = false;
          _error = 'No se pudo cargar el directorio. Reintenta.';
        });
      }
    }
  }

  List<Professor> get _filteredProfessors => filterProfessors(
    _professors,
    query: _searchQuery,
    campusId: _campusFilter,
    locationId: _locationFilter,
    weekday: _dayFilter,
    hasOfficeHours: _hoursFilter,
    campusByLocation: _campusByLocation,
  );

  Widget _filters() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Card(
      color: const Color(0xFFE8F0FA),
      elevation: 2,
      shadowColor: AppColors.uctBlue.withValues(alpha: .18),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.tune, color: AppColors.uctBlue),
        title: const Text(
          'Filtrar',
          style: TextStyle(
            color: AppColors.uctBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .3,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_campusError)
                    TextButton(
                      onPressed: _loadProfessors,
                      child: const Text(
                        'No se pudieron cargar los campus. Reintentar',
                      ),
                    ),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('campus:$_campusFilter'),
                    initialValue: _campusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Campus'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos los campus'),
                      ),
                      ..._campuses.map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _campusFilter = value;
                      _locationFilter = null;
                      _page = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('location:$_campusFilter:$_locationFilter'),
                    initialValue: _locationFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Lugar de atención',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos los lugares'),
                      ),
                      ..._locations.entries
                          .where(
                            (e) =>
                                _campusFilter == null ||
                                _campusByLocation[e.key] == _campusFilter,
                          )
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          ),
                    ],
                    onChanged: (value) => setState(() {
                      _locationFilter = value;
                      _page = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    key: ValueKey('day:$_dayFilter'),
                    initialValue: _dayFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Día de atención',
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todos los días'),
                      ),
                      for (final (index, name) in [
                        'Lunes',
                        'Martes',
                        'Miércoles',
                        'Jueves',
                        'Viernes',
                        'Sábado',
                        'Domingo',
                      ].indexed)
                        DropdownMenuItem(value: index + 1, child: Text(name)),
                    ],
                    onChanged: (value) => setState(() {
                      _dayFilter = value;
                      _page = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<bool?>(
                    key: ValueKey('hours:$_hoursFilter'),
                    initialValue: _hoursFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Horario registrado',
                    ),
                    items: const [
                      DropdownMenuItem<bool?>(
                        value: null,
                        child: Text('Todos los profesores'),
                      ),
                      DropdownMenuItem(
                        value: true,
                        child: Text('Con atención semanal'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Sin horario registrado'),
                      ),
                    ],
                    onChanged: (value) => setState(() {
                      _hoursFilter = value;
                      _page = 0;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Limpiar filtros'),
                      onPressed: () => setState(() {
                        _campusFilter = null;
                        _locationFilter = null;
                        _dayFilter = null;
                        _hoursFilter = null;
                        _page = 0;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showProfessor(Professor professor) async {
    final token = _session.token;
    await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfessorDetailScreen(
          professor: professor,
          repository: _repository,
          locations: _locations,
          locationError: _locationError,
        ),
      ),
    );
    if (!mounted || token != _session.token) return;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) => _buildDirectory(context),
    );
  }

  Widget _buildDirectory(BuildContext context) {
    final filtered = _filteredProfessors;
    final pages = (filtered.length / 10).ceil();
    final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
    final list = filtered.skip(page * 10).take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Directorio de Profesores',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Actualizar directorio',
            onPressed: _loading ? null : _loadProfessors,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              if (_error != null)
                ListTile(
                  title: Text(_error!),
                  trailing: IconButton(
                    tooltip: 'Reintentar carga',
                    onPressed: _loadProfessors,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (val) => setState(() {
                    _searchQuery = val;
                    _page = 0;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Buscar profesor...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.uctBlue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.fieldBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.fieldBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.uctBlue,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ),
              _filters(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? const Center(
                        child: Text('El directorio no está disponible.'),
                      )
                    : list.isEmpty
                    ? const Center(child: Text('No se encontraron profesores.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final prof = list[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppColors.fieldBorder,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFE7EEF5),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: AppColors.uctBlue,
                                  ),
                                ),
                                title: Text(
                                  prof.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  prof.department.isEmpty
                                      ? prof.email
                                      : prof.department,
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: AppColors.uctBlue,
                                ),
                                onTap: () => _showProfessor(prof),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (pages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: 'Página anterior',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: page == 0
                          ? null
                          : () => setState(() => _page = page - 1),
                    ),
                    Text('${page + 1} de $pages'),
                    IconButton(
                      tooltip: 'Página siguiente',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: page + 1 >= pages
                          ? null
                          : () => setState(() => _page = page + 1),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
