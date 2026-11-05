import 'package:flutter/material.dart';

import '../../../application/contributions/user_objects.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/lost_objects_repository_impl.dart';
import '../../../data/repositories/reports_repository_impl.dart';
import '../../../domain/entities/lost_object.dart';
import '../../../domain/repositories/lost_objects_repository.dart';
import '../../../domain/repositories/reports_repository.dart';
import '../login/session_required_view.dart';
import '../lost_objects/lost_object_detail_screen.dart';
import '../lost_objects/widgets/lost_object_status_badge.dart';

class MyLostItemsScreen extends StatelessWidget {
  const MyLostItemsScreen({
    super.key,
    this.onNavigateToTab,
    this.reportsRepository,
    this.objectsRepository,
  });
  final Function(int)? onNavigateToTab;
  final ReportsRepository? reportsRepository;
  final LostObjectsRepository? objectsRepository;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    builder: (_) => _Objects(
      key: ValueKey(ApiClientProvider.session.token),
      reports: reportsRepository ?? ReportsRepositoryImpl(),
      objects: objectsRepository ?? LostObjectsRepositoryImpl(),
    ),
  );
}

class _Objects extends StatefulWidget {
  const _Objects({super.key, required this.reports, required this.objects});
  final ReportsRepository reports;
  final LostObjectsRepository objects;
  @override
  State<_Objects> createState() => _ObjectsState();
}

class _ObjectsState extends State<_Objects> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late Future<({List<LostObject> items, int unavailable})> _data = _load();
  LostObjectStatus? _status;
  int _page = 0;
  Future<({List<LostObject> items, int unavailable})> _load() =>
      loadUserObjects(widget.reports, widget.objects, _session);
  void _refresh() {
    if (mounted && _session.token == _token)
      setState(() {
        _data = _load();
        _page = 0;
      });
  }

  Future<void> _open(LostObject item) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LostObjectDetailScreen(
          objectId: item.id,
          repository: widget.objects,
          reportedByMe: true,
        ),
      ),
    );
    if (mounted && _session.token == _token) _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Objetos reportados'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Actualizar objetos',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: FutureBuilder<({List<LostObject> items, int unavailable})>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron cargar tus objetos reportados.'),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            final data = snapshot.data!;
            final items = data.items
                .where((o) => _status == null || o.status == _status)
                .toList();
            final pages = (items.length / 10).ceil();
            final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${data.items.length} objetos disponibles vinculados a tus reportes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.uctBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (data.unavailable > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${data.unavailable} objetos vinculados ya no están disponibles.',
                    ),
                  ),
                const SizedBox(height: 20),
                DropdownButtonFormField<LostObjectStatus?>(
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: [
                    const DropdownMenuItem<LostObjectStatus?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...LostObjectStatus.values.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                    ),
                  ],
                  onChanged: (s) => setState(() {
                    _status = s;
                    _page = 0;
                  }),
                ),
                const SizedBox(height: 24),
                if (items.isEmpty)
                  const Text('No hay objetos reportados para este filtro.'),
                for (final item in items.skip(page * 10).take(10))
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: LostObjectStatusBadge(status: item.status),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(item),
                  ),
                if (pages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Página anterior',
                        onPressed: page == 0
                            ? null
                            : () => setState(() => _page = page - 1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text('${page + 1} de $pages'),
                      IconButton(
                        tooltip: 'Página siguiente',
                        onPressed: page + 1 >= pages
                            ? null
                            : () => setState(() => _page = page + 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
