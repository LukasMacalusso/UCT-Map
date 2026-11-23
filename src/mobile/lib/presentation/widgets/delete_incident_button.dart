import 'package:flutter/material.dart';

import '../../core/network/api_client_provider.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/app_permission.dart';
import '../../application/incidents/incident_deletion.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../data/repositories/lost_objects_repository_impl.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/repositories/lost_objects_repository.dart';
import 'campus_location_label.dart';

class DeleteIncidentButton extends StatefulWidget {
  const DeleteIncidentButton({
    super.key,
    required this.id,
    required this.title,
    required this.locationId,
    required this.object,
    this.reports,
    this.objects,
  });
  final String id;
  final String title;
  final String locationId;
  final bool object;
  final ReportsRepository? reports;
  final LostObjectsRepository? objects;
  @override
  State<DeleteIncidentButton> createState() => _DeleteIncidentButtonState();
}

class _DeleteIncidentButtonState extends State<DeleteIncidentButton> {
  bool _busy = false;
  bool get _allowed =>
      ApiClientProvider.session.isAuthenticated &&
      (widget.object
              ? AppPermission.manageObjects
              : AppPermission.manageReports)
          .allows(ApiClientProvider.session.currentUser?.role);
  Future<void> _delete() async {
    if (_busy || !_allowed) return;
    setState(() => _busy = true);
    final token = ApiClientProvider.session.token;
    final deletion = IncidentDeletion(
      session: ApiClientProvider.session,
      reports: widget.reports ?? ReportsRepositoryImpl(),
      objects: widget.objects ?? LostObjectsRepositoryImpl(),
    );
    try {
      final yes = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            widget.object ? '¿Eliminar objeto?' : '¿Eliminar incidencia?',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                CampusLocationLabel(id: widget.locationId),
                const SizedBox(height: 16),
                const Text(
                  'Se eliminará el registro de forma permanente. Esta acción no se puede deshacer.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade800,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (!mounted ||
          yes != true ||
          !_allowed ||
          ApiClientProvider.session.token != token)
        return;
      if (widget.object) {
        await deletion.deleteObject(widget.id);
      } else {
        await deletion.deleteReport(widget.id);
      }
      if (!mounted || ApiClientProvider.session.token != token) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted || ApiClientProvider.session.token != token) return;
      final message = error is StateError
          ? error.message.toString()
          : error is ApiException && error.statusCode == 404
          ? 'El registro ya no existe. Actualiza la lista.'
          : 'No se confirmó el borrado. Actualiza antes de reintentar.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: ApiClientProvider.session,
    builder: (_, _) => !_allowed
        ? const SizedBox.shrink()
        : TextButton.icon(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade800),
            icon: const Icon(Icons.delete_outline),
            label: Text(
              widget.object ? 'Eliminar objeto' : 'Eliminar incidencia',
            ),
          ),
  );
}
