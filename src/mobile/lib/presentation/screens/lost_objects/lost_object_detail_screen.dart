import '../../widgets/delete_incident_button.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/lost_objects_repository_impl.dart';
import '../../../domain/entities/lost_object.dart';
import '../../../domain/repositories/lost_objects_repository.dart';
import '../../widgets/campus_location_label.dart';
import '../login/session_required_view.dart';
import 'widgets/lost_object_status_badge.dart';

class LostObjectDetailScreen extends StatelessWidget {
  const LostObjectDetailScreen({
    super.key,
    required this.objectId,
    this.repository,
    this.reportedByMe = false,
  });
  final String objectId;
  final LostObjectsRepository? repository;
  final bool reportedByMe;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    builder: (_) => _Detail(
      key: ValueKey('${ApiClientProvider.session.token}:$objectId'),
      objectId: objectId,
      repository: repository ?? LostObjectsRepositoryImpl(),
      reportedByMe: reportedByMe,
    ),
  );
}

class _Detail extends StatefulWidget {
  const _Detail({
    super.key,
    required this.objectId,
    required this.repository,
    required this.reportedByMe,
  });
  final String objectId;
  final LostObjectsRepository repository;
  final bool reportedByMe;
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  late Future<LostObject> _data = _load();
  Future<LostObject> _load() async {
    final result = await widget.repository.getLostObjectById(widget.objectId);
    if (_session.token != _token)
      throw const UnauthorizedException('La sesión cambió.');
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detalle del objeto'),
      backgroundColor: AppColors.uctBlue,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          tooltip: 'Actualizar objeto',
          onPressed: () => setState(() => _data = _load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<LostObject>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    snapshot.error is ApiException &&
                            (snapshot.error as ApiException).statusCode == 404
                        ? 'Este objeto ya no está disponible.'
                        : 'No se pudo cargar el objeto.',
                  ),
                  TextButton(
                    onPressed: () => setState(() => _data = _load()),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        final item = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.uctBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: LostObjectStatusBadge(status: item.status),
                ),
                const SizedBox(height: 24),
                if (item.photoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.photoUrl,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 100,
                        child: Center(child: Text('Imagen no disponible')),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                CampusLocationLabel(id: item.structureId),
                if (item.date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '${item.date!.day}/${item.date!.month}/${item.date!.year}',
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DeleteIncidentButton(
                    id: item.id,
                    title: item.title,
                    locationId: item.structureId,
                    object: true,
                    objects: widget.repository,
                  ),
                ),
                if (widget.reportedByMe)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Vinculado a uno de tus reportes.'),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
