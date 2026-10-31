import 'package:flutter/material.dart';

import '../../../application/session/session_controller.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/navigation/app_routes.dart';
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
          } else {
            locationError = true;
          }
        } catch (_) {
          if (!current()) return;
          locationError = true;
        }
      }
      if (current()) {
        setState(() {
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

  List<Professor> get _filteredProfessors {
    final base = _professors;
    if (_searchQuery.trim().isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.department.toLowerCase().contains(q) ||
          p.office.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _showProfessor(Professor professor) async {
    final token = _session.token;
    final result = await Navigator.push<int>(
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
    if (result == 0) _goToMap(context, professor.name);
  }

  void _goToMap(BuildContext context, String profName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ubicando oficina de $profName en el mapa...'),
        duration: const Duration(seconds: 2),
      ),
    );

    if (widget.onNavigateToTab != null) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, 0);
      }
      widget.onNavigateToTab!(0);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, 0);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.initial, arguments: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) => _buildDirectory(context),
    );
  }

  Widget _buildDirectory(BuildContext context) {
    final list = _filteredProfessors;

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
                    onPressed: _loadProfessors,
                    icon: const Icon(Icons.refresh),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
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
            ],
          ),
        ),
      ),
    );
  }
}
