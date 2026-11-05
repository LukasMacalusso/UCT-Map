import 'package:flutter/material.dart';

import '../../../application/contributions/user_reports.dart';
import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/reports_repository_impl.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/repositories/reports_repository.dart';
import '../login/session_required_view.dart';
import '../tickets/ticket_detail_screen.dart';
import '../tickets/widgets/ticket_status_badge.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key, this.onNavigateToTab, this.repository});
  final Function(int)? onNavigateToTab;
  final ReportsRepository? repository;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    builder: (_) => _Reports(
      key: ValueKey(ApiClientProvider.session.token),
      repository: repository ?? ReportsRepositoryImpl(),
    ),
  );
}

class _Reports extends StatefulWidget {
  const _Reports({super.key, required this.repository});
  final ReportsRepository repository;
  @override
  State<_Reports> createState() => _ReportsState();
}

class _ReportsState extends State<_Reports> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late Future<List<Ticket>> _reports = _load();
  TicketStatus? _status;
  int _page = 0;
  static const _pageSize = 10;

  Future<List<Ticket>> _load() async => (await loadUserReports(
    widget.repository,
    _session,
  )).where((r) => r.complaintDetails != null).toList();

  Future<void> _refresh() async {
    if (!mounted || _session.token != _token) return;
    final future = _load();
    setState(() {
      _reports = future;
      _page = 0;
    });
    try {
      await future;
    } catch (_) {
      /* FutureBuilder presenta el error. */
    }
  }

  Future<void> _open(Ticket ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => SessionRequiredView(
          builder: (_) => TicketDetailScreen(
            ticketId: ticket.id,
            repository: widget.repository,
          ),
        ),
      ),
    );
    if (mounted && _session.token == _token) await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mis Reportes de Incidencias'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Actualizar reportes',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: FutureBuilder<List<Ticket>>(
          future: _reports,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron cargar tus reportes.'),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            final reports = snapshot.data!;
            final filtered = reports
                .where((r) => _status == null || r.ticketType == _status)
                .toList();
            final pages = (filtered.length / _pageSize).ceil();
            final page = pages == 0 ? 0 : _page.clamp(0, pages - 1);
            final visible = filtered.skip(page * _pageSize).take(_pageSize);
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '${reports.length} ${reports.length == 1 ? 'incidencia registrada' : 'incidencias registradas'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.uctBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<TicketStatus?>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: [
                      const DropdownMenuItem<TicketStatus?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...TicketStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                      ),
                    ],
                    onChanged: (s) => setState(() {
                      _status = s;
                      _page = 0;
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'No tienes incidencias para este filtro. Los reportes que crees aparecerán aquí.',
                      ),
                    ),
                  for (final ticket in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(
                          ticket.complaintDetails!.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              ticket.complaintDetails!.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            TicketStatusBadge(
                              status: ticket.ticketType,
                              isCompact: true,
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(ticket),
                      ),
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
              ),
            );
          },
        ),
      ),
    ),
  );
}
