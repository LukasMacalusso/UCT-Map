import 'package:flutter/material.dart';

import '../../core/network/api_client_provider.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/schedule_meeting.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/schedule_repository.dart';

class MeetingActions extends StatefulWidget {
  const MeetingActions({
    super.key,
    required this.meeting,
    required this.repository,
    required this.onChanged,
  });
  final ScheduleMeeting meeting;
  final ScheduleRepository repository;
  final VoidCallback onChanged;

  @override
  State<MeetingActions> createState() => _MeetingActionsState();
}

class _MeetingActionsState extends State<MeetingActions> {
  bool _busy = false;
  static String _label(MeetingStatus status) => switch (status) {
    MeetingStatus.confirmed => 'Confirmar cita',
    MeetingStatus.completed => 'Marcar completada',
    MeetingStatus.cancelled => 'Cancelar cita',
    MeetingStatus.pending => 'Pendiente',
  };

  Future<void> _change(MeetingStatus status) async {
    if (_busy) return;
    final session = ApiClientProvider.session;
    final revision = session.revision;
    final token = session.token;
    setState(() => _busy = true);
    if (status == MeetingStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancelar cita'),
          content: const Text(
            'La cita dejará de estar activa. ¿Deseas cancelarla?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Volver'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancelar cita'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) {
        setState(() => _busy = false);
        return;
      }
    }
    if (!mounted || session.token != token || session.revision != revision) {
      return;
    }
    try {
      final changed = await widget.repository.updateMeetingStatus(
        widget.meeting.id,
        status,
      );
      if (!mounted || session.token != token || session.revision != revision) {
        return;
      }
      if (!changed) throw StateError('Cambio no confirmado.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cita ${status.label.toLowerCase()}.')),
      );
      widget.onChanged();
    } catch (error) {
      if (!mounted || session.token != token || session.revision != revision) {
        return;
      }
      final message = switch (error) {
        ApiException(statusCode: 409) => 'La cita cambió. Actualizamos su estado; revisa antes de intentar otra acción.',
        ApiException(statusCode: 403) =>
          'No tienes permiso para cambiar esta cita.',
        ApiException(statusCode: 401) =>
          'Inicia sesión nuevamente para continuar.',
        _ => 'No se pudo verificar el cambio. Actualizamos la cita antes de que reintentes.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClientProvider.session.currentUser;
    final actions = widget.meeting.allowedTransitions(
      isTeacher:
          user?.role == UserRole.profesor &&
          user?.id == widget.meeting.teacherRefId,
      isStudent:
          user?.role == UserRole.estudiante &&
          user?.id == widget.meeting.studentRefId,
    );
    if (actions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _busy
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Semantics(
              container: true,
              button: true,
              child: PopupMenuButton<MeetingStatus>(
                tooltip: 'Acciones de la cita',
                onSelected: _change,
                itemBuilder: (_) => [
                  for (final status in actions)
                    PopupMenuItem(value: status, child: Text(_label(status))),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz, color: AppColors.uctBlue),
                      SizedBox(width: 8),
                      Text(
                        'Acciones',
                        style: TextStyle(color: AppColors.uctBlue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
