import '../../widgets/delete_incident_button.dart';

import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/problem_details.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/lost_objects_repository_impl.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/lost_object.dart';
import '../../../domain/repositories/campus_repository.dart';
import '../../../domain/repositories/lost_objects_repository.dart';
import '../../widgets/campus_location_label.dart';
import '../login/session_required_view.dart';
import 'widgets/lost_object_status_badge.dart';

class LostObjectDetailScreen extends StatelessWidget {
  const LostObjectDetailScreen({
    super.key,
    required this.objectId,
    this.repository,
    this.campusRepository,
    this.reportedByMe = false,
  });
  final String objectId;
  final LostObjectsRepository? repository;
  final CampusRepository? campusRepository;
  final bool reportedByMe;
  @override
  Widget build(BuildContext context) => SessionRequiredView(
    builder: (_) => _Detail(
      key: ValueKey('${ApiClientProvider.session.token}:$objectId'),
      objectId: objectId,
      repository: repository ?? LostObjectsRepositoryImpl(),
      campusRepository: campusRepository,
      reportedByMe: reportedByMe,
    ),
  );
}

class _Detail extends StatefulWidget {
  const _Detail({
    super.key,
    required this.objectId,
    required this.repository,
    this.campusRepository,
    required this.reportedByMe,
  });
  final String objectId;
  final LostObjectsRepository repository;
  final CampusRepository? campusRepository;
  final bool reportedByMe;
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;
  bool _isLoading = true;
  bool _hasChanged = false;
  String? _errorMessage;
  LostObject? _item;

  bool get _canManage =>
      _session.isAuthenticated &&
      AppPermission.manageObjects.allows(_session.currentUser?.role);

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.repository.getLostObjectById(widget.objectId);
      if (!mounted || _session.token != _token) return;
      setState(() {
        _item = result;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || _session.token != _token) return;
      final message = error is ApiException && error.statusCode == 404
          ? 'Este objeto ya no está disponible.'
          : 'No se pudo cargar el objeto.';
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus() async {
    if (!_canManage) return;
    final item = _item;
    if (item == null || item.id.isEmpty) return;
    final actionToken = _session.token;
    LostObjectStatus selectedStatus = item.status;

    final chosen = await showModalBottomSheet<LostObjectStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final hasChanges = selectedStatus != item.status;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Actualizar Estado',
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: LostObjectStatus.values.map((s) {
                      final isSel = selectedStatus == s;
                      return ChoiceChip(
                        avatar: isSel
                            ? const Icon(Icons.check, size: 14)
                            : null,
                        label: Text(s.label),
                        selected: isSel,
                        onSelected: (_) =>
                            setModalState(() => selectedStatus = s),
                      );
                    }).toList(),
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
                      onPressed: !hasChanges
                          ? null
                          : () {
                              if (!mounted ||
                                  !_canManage ||
                                  actionToken != _session.token) {
                                return;
                              }
                              Navigator.pop(ctx, selectedStatus);
                            },
                      child: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (chosen == null ||
        !mounted ||
        !_canManage ||
        actionToken != _session.token) {
      return;
    }

    try {
      await widget.repository.updateStatus(item.id, chosen);
      if (!mounted || actionToken != _session.token) return;
      _hasChanged = true;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Estado actualizado a "${chosen.label}"'),
            backgroundColor: const Color(0xFF047857),
          ),
        );
      await _fetchDetail();
    } catch (err) {
      if (!mounted || actionToken != _session.token) return;
      final message = switch (err) {
        ProblemDetailsException e => e.problemDetails.userMessage,
        ApiException e => e.message,
        _ => 'No se pudo actualizar el estado.',
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _session,
    builder: (context, _) => _buildContent(context),
  );

  Widget _buildContent(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) {
        Navigator.of(context).pop(_hasChanged);
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del objeto'),
        backgroundColor: AppColors.uctBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Actualizar objeto',
            onPressed: _fetchDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: _item != null && _item!.id.isNotEmpty && _canManage
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _changeStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.uctBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text(
                    'Cambiar Estado del Objeto',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            )
          : null,
    ),
  );

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null || _item == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? 'No se pudo cargar el objeto.'),
              TextButton(
                onPressed: _fetchDetail,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final item = _item!;
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
            CampusLocationLabel(
              id: item.structureId,
              repository: widget.campusRepository,
            ),
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
                campusRepository: widget.campusRepository,
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
  }
}
