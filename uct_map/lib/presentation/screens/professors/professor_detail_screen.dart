import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/professor.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../../widgets/office_hour_card.dart';
import '../login/session_required_view.dart';
import 'consultation_booking_screen.dart';

class ProfessorDetailScreen extends StatefulWidget {
  const ProfessorDetailScreen({
    super.key,
    required this.professor,
    required this.repository,
    required this.locations,
    this.locationError = false,
  });

  final Professor professor;
  final ScheduleRepository repository;
  final Map<String, String> locations;
  final bool locationError;

  @override
  State<ProfessorDetailScreen> createState() => _ProfessorDetailScreenState();
}

class _ProfessorDetailScreenState extends State<ProfessorDetailScreen> {
  final _session = ApiClientProvider.session;
  late final _token = _session.token;

  Future<void> _book() async {
    if (!_session.isAuthenticated ||
        _session.token != _token ||
        !AppPermission.bookConsultation.allows(_session.currentUser?.role)) {
      return;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationBookingScreen(
          professor: widget.professor,
          repository: widget.repository,
          locations: widget.locations,
        ),
      ),
    );
    if (!mounted || result != true || _session.token != _token) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cita solicitada correctamente al docente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    builder: (context) {
      if (_session.token != _token) {
        return Scaffold(
          appBar: AppBar(title: const Text('Ficha docente')),
          body: const Center(
            child: Text(
              'La sesión cambió. Vuelve a abrir la ficha desde el directorio.',
            ),
          ),
        );
      }
      final professor = widget.professor;
      final theme = Theme.of(context);
      final hours = [...professor.officeHours]
        ..sort((a, b) {
          final day = a.dayOfWeek.compareTo(b.dayOfWeek);
          return day == 0 ? a.startTime.compareTo(b.startTime) : day;
        });
      final canBook = AppPermission.bookConsultation.allows(
        _session.currentUser?.role,
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ficha docente'),
          backgroundColor: AppColors.uctBlue,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFE7EEF5),
                      child: Icon(
                        Icons.person_outline,
                        size: 32,
                        color: AppColors.uctBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            professor.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.uctBlue,
                            ),
                          ),
                          if (professor.department.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(professor.department),
                          ],
                          const SizedBox(height: 8),
                          SelectableText(
                            professor.email,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (professor.office.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(professor.office),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Horario de atención',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Revisa los días y el lugar de atención antes de elegir una cita.',
                ),
                const SizedBox(height: 20),
                if (hours.isEmpty)
                  const Text('Este docente aún no tiene horarios registrados.'),
                for (final hour in hours)
                  OfficeHourCard(
                    hour: hour,
                    location: widget.locations[hour.structureRefId],
                  ),
                if (widget.locationError)
                  const Text(
                    'No se pudieron cargar algunos lugares de atención. Vuelve al directorio y reintenta.',
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 0),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Ver en Mapa'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: canBook && hours.isNotEmpty
            ? SafeArea(
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _book,
                          icon: const Icon(Icons.calendar_month),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Agendar Cita'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      );
    },
  );
}
