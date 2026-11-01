import 'package:flutter/material.dart';

import '../../../core/network/api_client_provider.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/app_permission.dart';
import '../../../domain/entities/booking_interval.dart';
import '../../../domain/entities/professor.dart';
import '../../../domain/repositories/schedule_repository.dart';
import '../login/session_required_view.dart';

class ConsultationBookingScreen extends StatefulWidget {
  const ConsultationBookingScreen({
    super.key,
    required this.professor,
    required this.repository,
    required this.locations,
  });

  final Professor professor;
  final ScheduleRepository repository;
  final Map<String, String> locations;

  @override
  State<ConsultationBookingScreen> createState() =>
      _ConsultationBookingScreenState();
}

class _ConsultationBookingScreenState extends State<ConsultationBookingScreen> {
  final _session = ApiClientProvider.session;
  late final String? _token = _session.token;
  late final DateTime _firstDate = DateUtils.dateOnly(DateTime.now());
  late final DateTime _lastDate = DateTime(
    _firstDate.year,
    _firstDate.month,
    _firstDate.day + 60,
  );
  DateTime? _date;
  DateTime? _start;
  bool _sending = false;
  String? _error;
  String? _availabilityError;
  bool _loadingAvailability = true;
  int _availabilityRequest = 0;
  List<BookingInterval> _busy = [];
  final List<BookingInterval> _rejected = [];

  List<DateTime> _attentionSlots(DateTime date) {
    final now = DateTime.now();
    final slots =
        widget.professor.officeHours
            .expand((hour) => hour.slotsOn(date))
            .where((start) => start.isAfter(now))
            .toSet()
            .toList()
          ..sort();
    return slots;
  }

  List<DateTime> _slots(DateTime date) {
    if (_loadingAvailability || _availabilityError != null || _date != date) {
      return [];
    }
    return _attentionSlots(date)
        .where(
          (start) => ![
            ..._busy,
            ..._rejected,
          ].any((interval) => interval.overlaps(start)),
        )
        .toList();
  }

  Future<void> _refreshAvailability(DateTime date, {String? notice}) async {
    final request = ++_availabilityRequest;
    final previous = _start;
    setState(() {
      _date = date;
      _start = null;
      _busy = [];
      _loadingAvailability = true;
      _availabilityError = null;
      _error = notice;
    });
    try {
      final busy = await widget.repository.getBusyIntervals(
        teacherId: widget.professor.id,
        date: date,
      );
      if (!mounted ||
          request != _availabilityRequest ||
          _session.token != _token) {
        return;
      }
      setState(() {
        _busy = busy;
        _loadingAvailability = false;
        final slots = _slots(date);
        _start = slots.contains(previous) ? previous : slots.firstOrNull;
      });
    } catch (_) {
      if (!mounted ||
          request != _availabilityRequest ||
          _session.token != _token) {
        return;
      }
      setState(() {
        _loadingAvailability = false;
        _availabilityError = 'No se pudo comprobar qué horas están libres. Reintenta antes de reservar.';
      });
    }
  }

  @override
  void dispose() {
    _availabilityRequest++;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    for (var offset = 0; offset <= 60; offset++) {
      final date = DateTime(
        _firstDate.year,
        _firstDate.month,
        _firstDate.day + offset,
      );
      final slots = _attentionSlots(date);
      if (slots.isNotEmpty) {
        _date = date;
        break;
      }
    }
    if (_date != null) {
      _refreshAvailability(_date!);
    } else {
      _loadingAvailability = false;
    }
  }

  String _dateLabel(DateTime date) {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return '${days[date.weekday - 1]}, ${date.day}/${date.month}/${date.year}';
  }

  String _message(Object error) {
    if (error is NetworkException) {
      return 'No se pudo conectar. Conservamos tu selección; revisa tu conexión y reintenta.';
    }
    if (error is ApiException) {
      return switch (error.statusCode) {
        409 => 'Ese horario tiene un conflicto con otra cita del docente, estudiante o lugar. Elige otra hora.',
        400 => 'El servidor rechazó los datos de la cita. Revisa la fecha, la hora y el lugar antes de reintentar.',
        401 =>
          'Tu sesión venció. Inicia sesión nuevamente para solicitar la cita.',
        403 => 'Tu cuenta no tiene permiso para solicitar esta cita.',
        _ => 'El servicio de citas no está disponible. Conservamos tu selección para que reintentes.',
      };
    }
    return 'No se pudo confirmar la solicitud. Comprueba si la cita ya se registró antes de reintentar para evitar duplicados.';
  }

  Future<void> _submit() async {
    if (_sending ||
        _loadingAvailability ||
        _availabilityError != null ||
        _session.token != _token ||
        !_session.isAuthenticated ||
        !AppPermission.bookConsultation.allows(_session.currentUser?.role)) {
      return;
    }
    final start = _start;
    final hours = widget.professor.officeHours
        .where((h) => start != null && h.contains(start))
        .toList();
    if (start == null || !start.isAfter(DateTime.now()) || hours.isEmpty) {
      setState(
        () => _error =
            'Elige una fecha futura y una hora dentro de la atención docente.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.repository.createMeeting(
        teacherRefId: widget.professor.id,
        structureRefId: hours.first.structureRefId ?? '',
        scheduledAt: start,
      );
      if (!mounted || _session.token != _token) return;
      setState(() => _sending = false);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted || _session.token != _token) return;
      setState(() => _sending = false);
      if (error is ApiException && error.statusCode == 409) {
        _rejected.add(
          BookingInterval(
            start: start,
            end: start.add(const Duration(minutes: 30)),
          ),
        );
        await _refreshAvailability(
          _date!,
          notice: 'Ese horario acaba de ocuparse. Lo retiramos de las opciones; elige otra hora.',
        );
      } else {
        setState(() => _error = _message(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) => SessionRequiredView(
    permission: AppPermission.bookConsultation,
    builder: (context) {
      if (_session.token != _token) {
        return Scaffold(
          appBar: AppBar(title: const Text('Sesión cambiada')),
          body: const Center(
            child: Text('Vuelve a abrir la reserva desde tu cuenta.'),
          ),
        );
      }
      final theme = Theme.of(context);
      final date = _date;
      final start = _start;
      final hours = widget.professor.officeHours.where(
        (h) => start != null && h.contains(start),
      );
      final locationId = hours.isEmpty ? null : hours.first.structureRefId;
      final location = widget.locations[locationId] ?? 'Ubicación no informada';
      final localizations = MaterialLocalizations.of(context);
      return PopScope(
        canPop: !_sending,
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F5F8),
          appBar: AppBar(
            title: const Text('Agendar consulta'),
            backgroundColor: AppColors.uctBlue,
            foregroundColor: Colors.white,
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
                            const Icon(
                              Icons.event_available_outlined,
                              color: AppColors.uctYellow,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Elige cuándo consultar',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Las consultas duran 30 minutos. La reserva se confirma con el servicio al enviar la solicitud.',
                          style: TextStyle(
                            color: Color(0xFFE0EBF5),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (date == null)
                    const Text(
                      'No hay bloques de atención para reservar en los próximos 60 días.',
                    )
                  else ...[
                    Text(
                      'Fecha de la consulta',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.uctBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.uctBlue,
                        side: const BorderSide(color: Color(0xFFC1CEDB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(_dateLabel(date)),
                      ),
                      onPressed: _sending
                          ? null
                          : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _attentionSlots(date).isEmpty
                                    ? null
                                    : date,
                                firstDate: _firstDate,
                                lastDate: _lastDate,
                                selectableDayPredicate: (day) =>
                                    _attentionSlots(day).isNotEmpty,
                              );
                              if (picked == null || !mounted) return;
                              await _refreshAvailability(picked);
                            },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Hora de inicio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.uctBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_loadingAvailability)
                      const LinearProgressIndicator()
                    else if (_availabilityError != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _availabilityError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          TextButton.icon(
                            onPressed: () => _refreshAvailability(date),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      )
                    else if (_slots(date).isEmpty)
                      const Text(
                        'No quedan horas libres para este día. Elige otra fecha.',
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final slot in _slots(date))
                            ChoiceChip(
                              backgroundColor: Colors.white,
                              selectedColor: AppColors.uctBlue,
                              disabledColor: slot == start
                                  ? AppColors.uctBlue
                                  : Colors.white,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: slot == start
                                    ? Colors.white
                                    : AppColors.uctBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: slot == start
                                    ? AppColors.uctBlue
                                    : const Color(0xFFC1CEDB),
                              ),
                              label: Text(
                                localizations.formatTimeOfDay(
                                  TimeOfDay.fromDateTime(slot),
                                  alwaysUse24HourFormat: true,
                                ),
                              ),
                              selected: slot == start,
                              onSelected: _sending
                                  ? null
                                  : (_) => setState(() {
                                      _start = slot;
                                      _error = null;
                                    }),
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    if (!_loadingAvailability &&
                        _availabilityError == null) ...[
                      TextButton.icon(
                        onPressed: _sending
                            ? null
                            : () => _refreshAvailability(date),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar horas'),
                      ),
                    ],
                  ],
                  if (start != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14003865),
                            offset: Offset(0, 4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: DefaultTextStyle(
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: AppColors.ink,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                const Text(
                                  'Tu consulta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.uctBlue,
                                  ),
                                ),
                                Chip(
                                  label: const Text('30 minutos'),
                                  labelStyle: theme.textTheme.labelMedium
                                      ?.copyWith(color: AppColors.uctBlue),
                                  backgroundColor: const Color(0xFFE7EEF5),
                                  side: BorderSide.none,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(start), alwaysUse24HourFormat: true)} – ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(start.add(const Duration(minutes: 30))), alwaysUse24HourFormat: true)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.uctBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateLabel(start),
                              style: const TextStyle(color: AppColors.subtitle),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                height: 1,
                                color: AppColors.fieldBorder,
                              ),
                            ),
                            Text(
                              widget.professor.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 20,
                                  color: AppColors.subtitle,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: const TextStyle(
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.uctBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _sending ||
                            _loadingAvailability ||
                            _availabilityError != null ||
                            start == null
                        ? null
                        : _submit,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.event_available),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        _sending ? 'Enviando solicitud…' : 'Solicitar cita',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
