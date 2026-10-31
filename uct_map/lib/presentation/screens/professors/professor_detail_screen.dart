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
        backgroundColor: const Color(0xFFF3F5F8),
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.uctBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              professor.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.person_outline,
                            size: 28,
                            color: AppColors.uctYellow,
                          ),
                        ],
                      ),
                      if (professor.department.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          professor.department,
                          style: const TextStyle(color: Color(0xFFE0EBF5)),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SelectableText(
                        professor.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      if (professor.office.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 20,
                              color: Color(0xFFE0EBF5),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                professor.office,
                                style: const TextStyle(
                                  color: Color(0xFFE0EBF5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.uctBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Horario de atención',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.uctBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Revisa los días y el lugar de atención antes de elegir una cita.',
                  style: TextStyle(color: AppColors.subtitle, height: 1.5),
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
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.uctBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
