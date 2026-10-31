import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../domain/entities/app_permission.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/problem_details.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/report_dto.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/repositories/reports_repository.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';
import 'widgets/ticket_status_badge.dart';

/// Pantalla para listar, buscar, filtrar y gestionar Tickets / Reportes de Incidencias
/// consumiendo el microservicio de Incidentes en ASP.NET Core mediante Docker y API Gateway.
class TicketsScreen extends StatefulWidget {
  final ReportsRepository repository;
  final bool showAppBar;

  const TicketsScreen({
    super.key,
    required this.repository,
    this.showAppBar = true,
  });

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  bool get _canManage =>
      ApiClientProvider.session.isAuthenticated &&
      AppPermission.manageReports.allows(
        ApiClientProvider.session.currentUser?.role,
      );
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _isLoading = true;
  String? _errorMessage;
  PaginatedReportsResponse? _response;

  // Filtros activos
  String _searchQuery = '';
  TicketStatus? _typeFilter;
  String? _structureRefIdFilter;
  String _sortBy = 'ReportedAt';
  bool _descending = true;
  int _currentPage = 1;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
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
          _currentPage = 1;
        });
        _fetchTickets();
      }
    });
  }

  Future<void> _fetchTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final filter = ReportFilterParams(
      complaintTitle: _searchQuery.isNotEmpty ? _searchQuery : null,
      structureRefId: _structureRefIdFilter,
      type: _typeFilter,
      sortBy: _sortBy,
      descending: _descending,
      page: _currentPage,
      pageSize: _pageSize,
    );

    try {
      final res = await widget.repository.getReports(filter: filter);
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
        message = 'Error de conexión al cargar reportes.';
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTicketStatus(
    Ticket ticket, {
    required TicketStatus newStatus,
    ComplaintStatus? newComplainStatus,
  }) async {
    if (!mounted || !_canManage) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualizando estado a "${newStatus.label}"...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await widget.repository.updateReportStatus(
        ticket.id,
        status: newStatus,
        complainStatus: newComplainStatus ?? ticket.complaintDetails?.status,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte actualizado a "${newStatus.label}"'),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _fetchTickets();
    } catch (e) {
      if (!mounted) return;
      String message;
      if (e is ProblemDetailsException) {
        message = e.problemDetails.userMessage;
      } else if (e is ApiException) {
        message = e.message;
      } else {
        message = 'No se pudo actualizar el estado del reporte.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showStatusDialog(Ticket ticket) {
    if (!_canManage) return;
    final actionToken = ApiClientProvider.session.token;
    TicketStatus selectedTicketStatus = ticket.ticketType;
    ComplaintStatus? selectedComplaintStatus = ticket.complaintDetails?.status;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cambiar Estado del Reporte',
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
                    const SizedBox(height: 8),

                    // Estado general del ticket
                    const Text(
                      'Estado del Ticket (TicketStatus):',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: TicketStatus.values.map((s) {
                        final isSel = selectedTicketStatus == s;
                        return ChoiceChip(
                          avatar: isSel
                              ? const Icon(Icons.check, size: 14)
                              : null,
                          label: Text(s.label),
                          selected: isSel,
                          onSelected: (_) =>
                              setModalState(() => selectedTicketStatus = s),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Estado de la queja (si aplica)
                    if (ticket.complaintDetails != null) ...[
                      const Text(
                        'Estado de Queja / Reclamo (ComplaintStatus):',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ComplaintStatus.values.map((cs) {
                          final isSel = selectedComplaintStatus == cs;
                          return ChoiceChip(
                            avatar: isSel
                                ? const Icon(Icons.check, size: 14)
                                : null,
                            label: Text(cs.label),
                            selected: isSel,
                            onSelected: (_) => setModalState(
                              () => selectedComplaintStatus = cs,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

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
                          if (!mounted ||
                              !_canManage ||
                              actionToken != ApiClientProvider.session.token) {
                            return;
                          }
                          Navigator.pop(ctx);
                          _updateTicketStatus(
                            ticket,
                            newStatus: selectedTicketStatus,
                            newComplainStatus: selectedComplaintStatus,
                          );
                        },
                        child: const Text('Aplicar Cambios (PATCH)'),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ordenar por:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Fecha (ReportedAt)'),
                          selected: tempSortBy == 'ReportedAt',
                          onSelected: (val) =>
                              setModalState(() => tempSortBy = 'ReportedAt'),
                        ),
                        ChoiceChip(
                          label: const Text('Estado (Status)'),
                          selected: tempSortBy == 'Status',
                          onSelected: (val) =>
                              setModalState(() => tempSortBy = 'Status'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Orden descendente'),
                      subtitle: Text(
                        tempDesc
                            ? 'Más recientes primero'
                            : 'Más antiguos primero',
                      ),
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
                          _fetchTickets();
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
        builder: (_) => CreateTicketScreen(repository: widget.repository),
      ),
    );

    if (result == true) {
      _fetchTickets();
    }
  }

  void _openDetailScreen(Ticket ticket) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TicketDetailScreen(
          ticketId: ticket.id,
          repository: widget.repository,
        ),
      ),
    );

    if (result == true) {
      _fetchTickets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text(
                'Reportes de Incidencias',
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
                  onPressed: _fetchTickets,
                ),
              ],
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text(
          'Crear Reporte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
          // Buscador
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar por queja o descripción...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.hint),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.subtitle,
                size: 20,
              ),
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
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

          // Chips de filtro por TicketStatus
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', null),
                const SizedBox(width: 6),
                _buildFilterChip('Pendientes', TicketStatus.pending),
                const SizedBox(width: 6),
                _buildFilterChip('En Proceso', TicketStatus.inProcess),
                const SizedBox(width: 6),
                _buildFilterChip('Resueltos', TicketStatus.resolved),
                const SizedBox(width: 6),
                _buildFilterChip('Desestimados', TicketStatus.dismissed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, TicketStatus? status) {
    final isSelected = _typeFilter == status;
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
          _typeFilter = status;
          _currentPage = 1;
        });
        _fetchTickets();
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
              'Cargando reportes...',
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
      onRefresh: _fetchTickets,
      color: AppColors.uctBlue,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _buildPaginationBar();
          }
          return _buildTicketCard(items[index]);
        },
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    final complaint = ticket.complaintDetails;
    final title = complaint?.title.isNotEmpty == true
        ? complaint!.title
        : 'Reporte #${ticket.id.length > 8 ? ticket.id.substring(0, 8) : ticket.id}';

    return InkWell(
      onTap: () => _openDetailScreen(ticket),
      borderRadius: BorderRadius.circular(14),
      child: Container(
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TicketStatusBadge(status: ticket.ticketType),
                if (complaint != null)
                  ComplaintStatusBadge(status: complaint.status),
              ],
            ),
            const SizedBox(height: 10),

            // Título
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),

            // Descripción (si tiene)
            if (complaint?.description.isNotEmpty == true) ...[
              Text(
                complaint!.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.subtitle,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Estructura
            Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 14,
                  color: AppColors.uctBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Estructura: ${ticket.structureRefId}',
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
            const SizedBox(height: 4),

            // Fecha
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.hint,
                ),
                const SizedBox(width: 6),
                Text(
                  'Reportado: ${_formatDate(ticket.reportedAt)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.hint),
                ),
              ],
            ),

            // Objeto vinculado
            if (ticket.lostObjectId?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.link_rounded,
                      size: 13,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Objeto: ${ticket.lostObjectId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Acciones inferiores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estado: ${ticket.ticketType.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _canManage
                      ? () => _showStatusDialog(ticket)
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.uctBlue,
                    side: const BorderSide(color: AppColors.uctBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text(
                    'Cambiar Estado',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                    _fetchTickets();
                  }
                : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Anterior'),
          ),
          Text(
            'Página ${response.page} de ${response.totalPages}\n(${response.totalCount} reportes)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppColors.subtitle),
          ),
          OutlinedButton.icon(
            onPressed: response.hasNextPage
                ? () {
                    setState(() => _currentPage++);
                    _fetchTickets();
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
              'No se encontraron reportes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No hay registros que coincidan con los filtros de búsqueda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _typeFilter = null;
                  _structureRefIdFilter = null;
                  _currentPage = 1;
                });
                _fetchTickets();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.uctBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
              'Error al consultar el servicio',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Ocurrió un error al cargar los reportes.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.subtitle),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchTickets,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.uctBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
