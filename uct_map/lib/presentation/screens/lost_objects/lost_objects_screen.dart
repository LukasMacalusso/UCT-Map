import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/problem_details.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/lost_object_dto.dart';
import '../../../domain/entities/lost_object.dart';
import '../../../domain/repositories/lost_objects_repository.dart';
import '../login/session_required_view.dart';
import 'create_lost_object_screen.dart';
import 'widgets/lost_object_status_badge.dart';

/// Pantalla principal para listar, buscar, filtrar y gestionar Objetos Perdidos
/// consumiendo el microservicio de Incidentes en ASP.NET Core vía API Gateway.
class LostObjectsScreen extends StatefulWidget {
  final LostObjectsRepository repository;
  final bool showAppBar;

  const LostObjectsScreen({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });

  @override
  State<LostObjectsScreen> createState() => _LostObjectsScreenState();
}

class _LostObjectsScreenState extends State<LostObjectsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoading = true;
  String? _errorMessage;
  PaginatedLostObjectsResponse? _response;

  // Filtros activos
  String _searchQuery = '';
  LostObjectStatus? _statusFilter;
  String? _structureIdFilter;
  String _sortBy = 'ReportedAt';
  bool _descending = true;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchObjects();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim();
          _currentPage = 1; // Reinicia a primera página al buscar
        });
        _fetchObjects();
      }
    });
  }

  Future<void> _fetchObjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final filter = LostObjectFilterParams(
      title: _searchQuery.isNotEmpty ? _searchQuery : null,
      structureId: _structureIdFilter,
      status: _statusFilter,
      sortBy: _sortBy,
      descending: _descending,
      page: _currentPage,
      pageSize: _pageSize,
    );

    try {
      final res = await widget.repository.getLostObjects(filter: filter);
      if (mounted) {
        setState(() {
          _response = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is ProblemDetailsException) {
        message = e.problemDetails.userMessage;
      } else if (e is ApiException) {
        message = e.message;
      } else {
        message = 'Error de conexión al cargar objetos perdidos.';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(LostObject item, LostObjectStatus newStatus) async {
    if (item.status == newStatus) return;

    // Mostrar feedback inmediato
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualizando estado a ${newStatus.label}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await widget.repository.updateStatus(item.id, newStatus);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado a "${newStatus.label}"'),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchObjects();
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is ProblemDetailsException) {
        message = e.problemDetails.userMessage;
      } else if (e is ApiException) {
        message = e.message;
      } else {
        message = 'No se pudo actualizar el estado.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: () => _changeStatus(item, newStatus),
          ),
        ),
      );
    }
  }

  void _showStatusDialog(LostObject item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cambiar Estado del Objeto',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
                ),
                const SizedBox(height: 16),
                ...LostObjectStatus.values.map((s) {
                  final isSelected = item.status == s;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: LostObjectStatusBadge(status: s, isCompact: true),
                    title: Text(
                      s.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.uctBlue : AppColors.ink,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.uctBlue)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _changeStatus(item, s);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSortFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String tempSortBy = _sortBy;
        bool tempDesc = _descending;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opciones de Ordenamiento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ordenar por:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Fecha (ReportedAt)'),
                          selected: tempSortBy == 'ReportedAt',
                          onSelected: (val) => setModalState(() => tempSortBy = 'ReportedAt'),
                        ),
                        ChoiceChip(
                          label: const Text('Título'),
                          selected: tempSortBy == 'Title',
                          onSelected: (val) => setModalState(() => tempSortBy = 'Title'),
                        ),
                        ChoiceChip(
                          label: const Text('Estado'),
                          selected: tempSortBy == 'Status',
                          onSelected: (val) => setModalState(() => tempSortBy = 'Status'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Orden descendente'),
                      subtitle: Text(tempDesc ? 'Más recientes primero' : 'Más antiguos primero'),
                      value: tempDesc,
                      onChanged: (val) => setModalState(() => tempDesc = val),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.uctBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _sortBy = tempSortBy;
                            _descending = tempDesc;
                            _currentPage = 1;
                          });
                          _fetchObjects();
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCreateScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionRequiredView(
          builder: (_) => CreateLostObjectScreen(repository: widget.repository),
        ),
      ),
    );

    if (mounted && result == true) {
      _fetchObjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                'Objetos Perdidos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: AppColors.uctBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Ordenar',
                  onPressed: _showSortFilterSheet,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar',
                  onPressed: _fetchObjects,
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Reportar Objeto', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por título...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.hint),
              prefixIcon: const Icon(Icons.search, color: AppColors.subtitle, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Chips de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', null),
                const SizedBox(width: 6),
                _buildFilterChip('Pendientes', LostObjectStatus.pending),
                const SizedBox(width: 6),
                _buildFilterChip('En Proceso', LostObjectStatus.inProcess),
                const SizedBox(width: 6),
                _buildFilterChip('Resueltos', LostObjectStatus.resolved),
                const SizedBox(width: 6),
                _buildFilterChip('Cancelados', LostObjectStatus.canceled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, LostObjectStatus? status) {
    final isSelected = _statusFilter == status;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.ink,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.uctBlue,
      backgroundColor: const Color(0xFFF1F5F9),
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (_) {
        setState(() {
          _statusFilter = status;
          _currentPage = 1;
        });
        _fetchObjects();
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.uctBlue),
            SizedBox(height: 16),
            Text(
              'Cargando objetos perdidos...',
              style: TextStyle(color: AppColors.subtitle, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    final items = _response?.items ?? [];
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _fetchObjects,
      color: AppColors.uctBlue,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _buildPaginationBar();
          }
          return _buildObjectCard(items[index]);
        },
      ),
    );
  }

  Widget _buildObjectCard(LostObject item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen superior o Placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF1F5F9),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined,
                                  size: 36, color: Colors.grey.shade400),
                              const SizedBox(height: 4),
                              Text(
                                'Imagen no disponible',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFFF8FAFC),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  // Badge de estado en esquina superior izquierda
                  Positioned(
                    top: 10,
                    left: 10,
                    child: LostObjectStatusBadge(status: item.status),
                  ),
                ],
              ),
            ),
          ),

          // Información
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),

                // Descripción
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.subtitle,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Estructura / Edificio
                Row(
                  children: [
                    const Icon(Icons.apartment_rounded, size: 14, color: AppColors.uctBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Estructura: ${item.structureId}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          color: AppColors.subtitle,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Fecha
                if (item.date != null)
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.hint),
                      const SizedBox(width: 6),
                      Text(
                        'Registrado: ${_formatDate(item.date!)}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.hint),
                      ),
                    ],
                  ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Botón para cambiar estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estado: ${item.status.label}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    OutlinedButton.icon(
                      onPressed: item.id.isNotEmpty
                          ? () => _showStatusDialog(item)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.uctBlue,
                        side: const BorderSide(color: AppColors.uctBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 16),
                      label: const Text('Cambiar Estado', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    final response = _response;
    if (response == null || response.totalPages <= 1) {
      return const SizedBox(height: 20);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: response.hasPreviousPage
                ? () {
                    setState(() => _currentPage--);
                    _fetchObjects();
                  }
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Anterior'),
          ),
          Text(
            'Página ${response.page} de ${response.totalPages}\n(${response.totalCount} objetos)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppColors.subtitle),
          ),
          OutlinedButton.icon(
            onPressed: response.hasNextPage
                ? () {
                    setState(() => _currentPage++);
                    _fetchObjects();
                  }
                : null,
            icon: const Icon(Icons.chevron_right, size: 18),
            label: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.subtitle,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No se encontraron objetos',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'No hay registros que coincidan con los filtros de búsqueda aplicados.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _statusFilter = null;
                  _structureIdFilter = null;
                  _currentPage = 1;
                });
                _fetchObjects();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.uctBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Limpiar Filtros'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'No se pudo conectar con el servicio',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Ocurrió un error al consultar los datos.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchObjects,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.uctBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
