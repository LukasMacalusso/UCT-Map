import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/incident_remote_ds.dart';
import '../../../domain/entities/lost_item.dart';
import '../../../domain/repositories/incident_repository.dart';
import '../login/session_required_view.dart';
import 'lost_item_detail_screen.dart';

class LostFoundScreen extends StatefulWidget {
  final bool showAppBar;
  final Function(int)? onNavigateToTab;
  final IncidentRepository? incidentRepository;

  const LostFoundScreen({
    super.key,
    this.showAppBar = false,
    this.onNavigateToTab,
    this.incidentRepository,
  });

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  late final IncidentRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  List<LostItem> _items = [];
  bool _loading = true;
  String _selectedCampus = 'Todos los campus';
  bool _newerFirst = true;
  String _selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    _repository = widget.incidentRepository ?? IncidentRemoteDataSource();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);
    try {
      final list = await _repository.getLostItems();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _statusColor(LostItemStatus s) {
    switch (s) {
      case LostItemStatus.publicado:
        return const Color(0xFF10B981);
      case LostItemStatus.enCustodia:
        return Colors.orange;
      case LostItemStatus.entregado:
        return AppColors.uctBlue;
      case LostItemStatus.cerrado:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Documentos':
        return Icons.badge_outlined;
      case 'Llaves':
        return Icons.key_outlined;
      case 'Tecnologia':
        return Icons.calculate_outlined;
      case 'Ropa':
        return Icons.checkroom_outlined;
      case 'Mochilas':
        return Icons.backpack_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Documentos':
        return Colors.blue;
      case 'Llaves':
        return Colors.amber;
      case 'Tecnologia':
        return Colors.purple;
      case 'Ropa':
        return Colors.teal;
      case 'Mochilas':
        return Colors.brown;
      default:
        return AppColors.uctBlue;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) {
      return 'hace ${diff.inDays} ${diff.inDays == 1 ? 'dia' : 'dias'}';
    } else if (diff.inHours >= 1) {
      return 'hace ${diff.inHours} ${diff.inHours == 1 ? 'hora' : 'horas'}';
    } else {
      return 'hace ${diff.inMinutes} min';
    }
  }

  List<LostItem> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    List<LostItem> result =
        _items.isNotEmpty ? List.from(_items) : List.from(mockLostItems);

    if (_selectedCampus != 'Todos los campus') {
      result = result.where((i) => i.campus == _selectedCampus).toList();
    }
    if (_selectedCategory != 'Todos') {
      result =
          result.where((i) => i.category == _selectedCategory).toList();
    }
    if (query.isNotEmpty) {
      result = result
          .where((i) =>
              i.title.toLowerCase().contains(query) ||
              i.building.toLowerCase().contains(query) ||
              i.ticketNumber.toLowerCase().contains(query) ||
              i.reportedBy.toLowerCase().contains(query))
          .toList();
    }
    result.sort((a, b) => _newerFirst
        ? b.reportedAt.compareTo(a.reportedAt)
        : a.reportedAt.compareTo(b.reportedAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.uctBlue,
              foregroundColor: Colors.white,
              title: const Text(
                'Objetos Perdidos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          // ===== Barra de filtros =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                // Buscador
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.fieldBorder),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: AppColors.uctBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Buscar por nombre, ticket o lugar...',
                            border: InputBorder.none,
                            hintStyle:
                                TextStyle(color: AppColors.hint, fontSize: 13),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _searchController.clear()),
                          child: const Icon(Icons.clear,
                              size: 18, color: AppColors.hint),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Campus + Ordenar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.fieldBorder),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade50,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCampus,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.subtitle),
                            style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            items: lostItemCampusList
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.location_on_outlined,
                                              size: 14,
                                              color: AppColors.subtitle),
                                          const SizedBox(width: 5),
                                          Expanded(
                                              child: Text(c,
                                                  overflow:
                                                      TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCampus = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _newerFirst = !_newerFirst),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.fieldBorder),
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.uctBlue.withValues(alpha: 0.06),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _newerFirst
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              size: 15,
                              color: AppColors.uctBlue,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _newerFirst ? 'Reciente' : 'Antiguo',
                              style: const TextStyle(
                                  color: AppColors.uctBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Chips de categoria
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: lostItemCategories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor:
                              AppColors.uctBlue.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.uctBlue,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.uctBlue
                                : Colors.grey.shade600,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.fieldBorder),

          // ===== Lista de objetos =====
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'No hay objetos con estos filtros.',
                              style: TextStyle(
                                  color: AppColors.subtitle, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _LostItemCard(
                      item: items[i],
                      statusColor: _statusColor(items[i].currentStatus),
                      categoryIcon: _categoryIcon(items[i].category),
                      categoryColor: _categoryColor(items[i].category),
                      timeAgo: _timeAgo(items[i].reportedAt),
                      onNavigateToTab: widget.onNavigateToTab,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lost_found_fab',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Formulario para publicar objeto perdido')),
          );
        },
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Publicar objeto',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: tarjeta de objeto perdido
// ---------------------------------------------------------------------------
class _LostItemCard extends StatelessWidget {
  final LostItem item;
  final Color statusColor;
  final IconData categoryIcon;
  final Color categoryColor;
  final String timeAgo;
  final Function(int)? onNavigateToTab;

  const _LostItemCard({
    required this.item,
    required this.statusColor,
    required this.categoryIcon,
    required this.categoryColor,
    required this.timeAgo,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Zona de imagen con overlays ----
          Stack(
            children: [
              // Placeholder de imagen (zona grande)
              item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) =>
                          _CardImageBanner(color: categoryColor, icon: categoryIcon, category: item.category),
                    )
                  : _CardImageBanner(
                      color: categoryColor,
                      icon: categoryIcon,
                      category: item.category,
                    ),
              // Estado (esquina superior izquierda)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    item.currentStatus.label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              // Ticket (esquina superior derecha)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.ticketNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ---- Info del objeto ----
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titulo
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),

                // Reportado por
                _InfoRow(
                  icon: Icons.person_outline,
                  text: 'Encontrado por: ${item.reportedBy}',
                ),
                const SizedBox(height: 5),

                // Ubicacion
                _InfoRow(
                  icon: Icons.apartment_outlined,
                  text: '${item.building}  •  ${item.campus}',
                ),
                const SizedBox(height: 5),

                // Tiempo
                _InfoRow(
                  icon: Icons.schedule_outlined,
                  text: 'Publicado $timeAgo',
                  isSubtle: true,
                ),
                const SizedBox(height: 14),

                // Boton ver detalle
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionRequiredView(
                            builder: (_) => LostItemDetailScreen(
                              item: item,
                              onNavigateToTab: onNavigateToTab,
                            ),
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.uctBlue,
                      side: const BorderSide(
                          color: AppColors.uctBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text(
                      'Ver detalle y reclamar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: banner de imagen con icono de categoria (placeholder)
// ---------------------------------------------------------------------------
class _CardImageBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String category;

  const _CardImageBanner({
    required this.color,
    required this.icon,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_outlined,
                  size: 12, color: color.withValues(alpha: 0.5)),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: fila de informacion reutilizable
// ---------------------------------------------------------------------------
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isSubtle;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.isSubtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 15,
          color: isSubtle ? AppColors.hint : AppColors.uctBlue,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isSubtle ? AppColors.hint : AppColors.subtitle,
              fontStyle: isSubtle ? FontStyle.italic : FontStyle.normal,
              fontWeight:
                  isSubtle ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
