import 'package:flutter/material.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/lost_item.dart';
import '../login/session_required_view.dart';
import '../lost_found/lost_item_detail_screen.dart';

class MyLostItemsScreen extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const MyLostItemsScreen({super.key, this.onNavigateToTab});

  @override
  State<MyLostItemsScreen> createState() => _MyLostItemsScreenState();
}

class _MyLostItemsScreenState extends State<MyLostItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Objetos reportados por el usuario
  final List<LostItem> _myItems = [
    LostItem(
      id: 'my-1',
      ticketNumber: '#TKT-UCT-0955',
      title: 'Mochila negra Samsonite con notebook',
      description:
          'Mochila Samsonite color negro con cierre plateado. En su interior contiene un notebook Dell Inspiron y un estuche azul. Olvidada en biblioteca San Francisco.',
      category: 'Mochilas y Bolsos',
      campus: 'Campus San Francisco',
      building: 'Edificio B - Biblioteca Central',
      reportedBy: 'Patricio Benavides (Estudiante)',
      reportedAt: DateTime(2026, 9, 15, 14, 30),
      currentStatus: LostItemStatus.enCustodia,
      contactInfo: 'Custodia Central de Seguridad, Campus San Francisco',
      imageUrl: null,
      statusHistory: [
        LostItemStatusEvent(
          status: LostItemStatus.publicado,
          at: DateTime(2026, 9, 15, 14, 30),
          by: 'Patricio Benavides',
          note: 'Reporte ingresado por el estudiante.',
        ),
        LostItemStatusEvent(
          status: LostItemStatus.enCustodia,
          at: DateTime(2026, 9, 16, 9, 10),
          by: 'Jefe Seguridad UCT',
          note: 'El auxiliar de aseo encontro la mochila en el 2do piso de Biblioteca y la entrego en custodia.',
        ),
      ],
    ),
    LostItem(
      id: 'my-2',
      ticketNumber: '#TKT-UCT-0842',
      title: 'Billetera de cuero con carnet y TNE',
      description:
          'Billetera de cuero color café oscuro con carnet de identidad, tarjeta TNE institucional y pase de micro.',
      category: 'Documentos',
      campus: 'Campus San Juan Pablo II',
      building: 'Edificio C - Aula C-204',
      reportedBy: 'Patricio Benavides (Estudiante)',
      reportedAt: DateTime(2026, 9, 10, 11, 20),
      currentStatus: LostItemStatus.entregado,
      contactInfo: 'Portería Edificio C',
      imageUrl: null,
      statusHistory: [
        LostItemStatusEvent(
          status: LostItemStatus.publicado,
          at: DateTime(2026, 9, 10, 11, 20),
          by: 'Patricio Benavides',
          note: 'Reporte ingresado.',
        ),
        LostItemStatusEvent(
          status: LostItemStatus.enCustodia,
          at: DateTime(2026, 9, 11, 8, 30),
          by: 'Portería Edificio C',
          note: 'Entregada por un compañero de curso.',
        ),
        LostItemStatusEvent(
          status: LostItemStatus.entregado,
          at: DateTime(2026, 9, 11, 16, 00),
          by: 'Seguridad Campus',
          note: 'Devuelta satisfactoriamente al titular tras verificar identidad.',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(LostItemStatus s) {
    switch (s) {
      case LostItemStatus.publicado:
        return const Color(0xFF0284C7);
      case LostItemStatus.enCustodia:
        return const Color(0xFFEA580C);
      case LostItemStatus.entregado:
        return const Color(0xFF16A34A);
      case LostItemStatus.cerrado:
        return Colors.grey;
    }
  }

  IconData _statusIcon(LostItemStatus s) {
    switch (s) {
      case LostItemStatus.publicado:
        return Icons.campaign_outlined;
      case LostItemStatus.enCustodia:
        return Icons.lock_clock_outlined;
      case LostItemStatus.entregado:
        return Icons.verified_outlined;
      case LostItemStatus.cerrado:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Objetos Reportados',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.uctYellow,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications_active_outlined, size: 20),
              text: 'Notificaciones',
            ),
            Tab(
              icon: Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Mis Reportes',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildItemsTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.onNavigateToTab != null) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context, 2);
                }
                widget.onNavigateToTab!(2); // Navega a la pestaña de objetos perdidos
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context, 2);
              } else {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.initial,
                  arguments: 2,
                );
              }
            },
            icon: const Icon(Icons.search),
            label: const Text('Explorar Banco de Objetos Perdidos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.uctBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Notificación de alta prioridad: ¡Objeto encontrado!
        Card(
          elevation: 0,
          color: const Color(0xFFF0FDF4), // verde suave
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF86EFAC), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Tu objeto ha sido encontrado!',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14532D),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Hoy, 09:15 hrs • Seguridad Campus',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'El objeto "Mochila negra Samsonite con notebook" que reportaste como perdido fue ingresado a la Custodia Central de Seguridad del Campus San Francisco.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF166534),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF15803D), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Puedes pasar a retirarlo de 08:30 a 18:00 hrs con tu TNE o Cédula de Identidad.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF14532D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SessionRequiredView(
                            builder: (_) => LostItemDetailScreen(
                              item: _myItems[0],
                              onNavigateToTab: widget.onNavigateToTab,
                            ),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Ver Detalles de Retiro y Ticket'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Notificación informativa secundaria
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.fieldBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.uctBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.history,
                    color: AppColors.uctBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Objeto entregado con éxito',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tu reporte de "Billetera de cuero con carnet y TNE" finalizó su ciclo. El objeto fue devuelto satisfactoriamente.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.subtitle,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '11 de Septiembre, 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _myItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _myItems[index];
        final statusColor = _statusColor(item.currentStatus);
        final statusIcon = _statusIcon(item.currentStatus);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SessionRequiredView(
                  builder: (_) => LostItemDetailScreen(
                    item: item,
                    onNavigateToTab: widget.onNavigateToTab,
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.fieldBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.uctBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.ticketNumber,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.uctBlue,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              item.currentStatus.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitle,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.fieldBorder),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.subtitle),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item.campus} • ${item.building}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.subtitle,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.hint),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
