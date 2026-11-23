import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_client_provider.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/office_hour.dart';
import '../../domain/entities/teacher_workload.dart';
import '../../domain/entities/booking_interval.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/entities/professor.dart';
import '../../domain/entities/schedule_meeting.dart';
import '../../domain/repositories/schedule_repository.dart';

/// Contratos de Identity y Schedule a través del Gateway.
class ScheduleRemoteDataSource implements ScheduleRepository {
  ScheduleRemoteDataSource({http.Client? client, ApiConfig? config})
    : _client = client ?? ApiClientProvider.defaultClient,
      _config = config ?? ApiConfig();

  final http.Client _client;
  final ApiConfig _config;

  Future<dynamic> _request(
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    bool patch = false,
  }) async {
    try {
      final uri = _config.uri(path, query);
      final response = patch
          ? await _client
                .patch(
                  uri,
                  headers: const {'Content-Type': 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(_config.timeout)
          : body == null
          ? await _client.get(uri).timeout(_config.timeout)
          : await _client
                .post(
                  uri,
                  headers: const {'Content-Type': 'application/json'},
                  body: jsonEncode(body),
                )
                .timeout(_config.timeout);
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException.fromResponse(response.statusCode, response.body);
      }
      return jsonDecode(response.body);
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException('Tiempo de espera agotado.');
    }
  }

  @override
  Future<List<Professor>> getProfessors() async {
    final session = ApiClientProvider.currentSession;
    final token = session?.token;
    void checkSession() {
      if (session != null && session.token != token) {
        throw const UnauthorizedException('La sesión cambió.');
      }
    }

    final users = await _request('/api/identity') as List;
    checkSession();
    final professors = <Professor>[];
    for (final user in users.whereType<Map<String, dynamic>>()) {
      checkSession();
      if (user['role'] != 'Teacher' || user['isSuspended'] == true) continue;
      final id = user['userId'] as String;
      final hours = await getOfficeHours(id);
      checkSession();
      professors.add(
        Professor(
          id: id,
          name: user['name'] as String,
          email: user['email'] as String,
          department: '',
          office: '',
          officeHours: hours,
          structureRefId: hours.isEmpty ? null : hours.first.structureRefId,
        ),
      );
    }
    return professors;
  }

  @override
  Future<List<OfficeHour>> getOfficeHours(String teacherId) async {
    final data = await _request(
      '/api/schedule/office-hours',
      query: {'teacherId': teacherId},
    ) as List;
    return data
        .map((h) => OfficeHour.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ScheduleMeeting>> getMyMeetings({
    DateTime? from,
    DateTime? to,
  }) async {
    final session = ApiClientProvider.session;
    final user = session.currentUser;
    final token = session.token;
    if (!session.isAuthenticated || user == null) {
      throw const UnauthorizedException();
    }
    if (user.role != UserRole.estudiante && user.role != UserRole.profesor) {
      throw const ForbiddenException();
    }
    final now = DateTime.now();
    final start = from ?? DateTime(now.year, now.month, now.day);
    final end = to ?? DateTime(now.year, now.month, now.day + 60);
    if (!end.isAfter(start)) throw ArgumentError('El rango no es válido.');
    final teacher = user.role == UserRole.profesor;
    final data = await _request(
      teacher
          ? '/api/schedule/meetings'
          : '/api/schedule/students/${user.id}/meetings',
      query: {
        'from': start.toIso8601String(),
        'to': end.toIso8601String(),
        if (teacher) 'teacherId': user.id,
      },
    );
    if (session.token != token) {
      throw const UnauthorizedException('La sesión cambió.');
    }
    if (!teacher && data['studentRefId'] != user.id) {
      throw const ForbiddenException('La agenda no corresponde a tu cuenta.');
    }
    final items = teacher ? data as List : data['meetings'] as List;
    final meetings = items
        .map((m) => ScheduleMeeting.fromJson(m as Map<String, dynamic>))
        .toList();
    if (meetings.any(
      (m) => (teacher ? m.teacherRefId : m.studentRefId) != user.id,
    )) {
      throw const ForbiddenException('La agenda no corresponde a tu cuenta.');
    }
    return meetings;
  }

  @override
  Future<TeacherWorkload> getMyWorkload({
    required DateTime from,
    required DateTime to,
  }) async {
    final session = ApiClientProvider.session;
    final token = session.token;
    final user = session.currentUser;
    if (!session.isAuthenticated || user == null) {
      throw const UnauthorizedException();
    }
    if (user.role != UserRole.profesor) throw const ForbiddenException();
    if (!to.isAfter(from)) throw ArgumentError('El rango no es válido.');
    final data = await _request(
      '/api/schedule/teachers/${user.id}/workload',
      query: {'from': from.toIso8601String(), 'to': to.toIso8601String()},
    );
    if (session.token != token) {
      throw const UnauthorizedException('La sesión cambió.');
    }
    final result = TeacherWorkload.fromJson(data as Map<String, dynamic>);
    if (result.teacherRefId != user.id ||
        result.officeHours.any((h) => h.teacherRefId != user.id) ||
        result.meetings.any((m) => m.teacherRefId != user.id)) {
      throw const ForbiddenException('El resumen no corresponde al docente.');
    }
    if (result.from != from || result.to != to) {
      throw const FormatException('El resumen no corresponde al período.');
    }
    return result;
  }

  @override
  Future<List<BookingInterval>> getBusyIntervals({
    required String teacherId,
    required DateTime date,
  }) async {
    final session = ApiClientProvider.session;
    final user = session.currentUser;
    final token = session.token;
    if (!session.isAuthenticated || user == null) {
      throw const UnauthorizedException();
    }
    final from = DateTime(date.year, date.month, date.day);
    final to = DateTime(date.year, date.month, date.day + 1);
    final query = {'from': from.toIso8601String(), 'to': to.toIso8601String()};
    final responses = await Future.wait([
      _request(
        '/api/schedule/meetings',
        query: {...query, 'teacherId': teacherId},
      ),
      _request('/api/schedule/students/${user.id}/meetings', query: query),
    ]);
    if (session.token != token) {
      throw const UnauthorizedException('La sesión cambió.');
    }
    final teacherMeetings = responses[0] as List;
    final ownMeetings = responses[1]['meetings'] as List;
    final intervals = <BookingInterval>[];
    for (final (items, ownerField, ownerId) in [
      (teacherMeetings, 'teacherRefId', teacherId),
      (ownMeetings, 'studentRefId', user.id),
    ]) {
      for (final value in items) {
        final item = value as Map<String, dynamic>;
        if (item[ownerField] != ownerId) {
          throw const ForbiddenException(
            'La respuesta no corresponde a la consulta.',
          );
        }
        final status = MeetingStatusExt.fromString(item['status'] as String?);
        if (status == MeetingStatus.cancelled) continue;
        final start = DateTime.tryParse(item['scheduledAt'] as String? ?? '');
        final duration = item['durationMinutes'];
        if (start == null || duration is! int || duration <= 0) {
          throw const FormatException('Intervalo ocupado inválido.');
        }
        intervals.add(
          BookingInterval(
            start: start,
            end: start.add(Duration(minutes: duration)),
          ),
        );
      }
    }
    return intervals;
  }

  @override
  Future<ScheduleMeeting> createMeeting({
    required String teacherRefId,
    required String structureRefId,
    required DateTime scheduledAt,
    String? studentRefId,
    int durationMinutes = 30,
  }) async {
    final student = studentRefId ?? ApiClientProvider.session.currentUser?.id;
    if (student == null) throw const UnauthorizedException();
    final data = await _request(
      '/api/schedule/meetings',
      body: {
        'teacherRefId': teacherRefId,
        'studentRefId': student,
        'structureRefId': structureRefId.isEmpty ? null : structureRefId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
      },
    );
    return ScheduleMeeting.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<bool> updateMeetingStatus(
    String meetingId,
    MeetingStatus status,
  ) async {
    final session = ApiClientProvider.session;
    final user = session.currentUser;
    final token = session.token;
    final revision = session.revision;
    if (!session.isAuthenticated || user == null) {
      throw const UnauthorizedException();
    }
    if (user.role != UserRole.estudiante && user.role != UserRole.profesor) {
      throw const ForbiddenException();
    }
    if (meetingId.isEmpty) throw ArgumentError('Cita requerida.');
    void checkSession() {
      if (session.token != token || session.revision != revision) {
        throw const UnauthorizedException('La sesión cambió.');
      }
    }

    Future<ScheduleMeeting> read() async {
      final data = await _request(
        '/api/schedule/meetings/${Uri.encodeComponent(meetingId)}',
      );
      checkSession();
      final meeting = ScheduleMeeting.fromJson(data as Map<String, dynamic>);
      if (meeting.id != meetingId) {
        throw const FormatException('Cita incorrecta.');
      }
      return meeting;
    }

    final current = await read();
    final teacher =
        user.role == UserRole.profesor && current.teacherRefId == user.id;
    final student =
        user.role == UserRole.estudiante && current.studentRefId == user.id;
    if ((!teacher && !student) ||
        (!teacher && status != MeetingStatus.cancelled)) {
      throw const ForbiddenException(
        'No puedes realizar este cambio de estado.',
      );
    }
    if (!current
        .allowedTransitions(isTeacher: teacher, isStudent: student)
        .contains(status)) {
      throw const ConflictException('La cita ya cambió de estado.');
    }
    checkSession();
    try {
      final data = await _request(
        '/api/schedule/meetings/${Uri.encodeComponent(meetingId)}/status',
        patch: true,
        body: {'status': status.name},
      );
      checkSession();
      final updated = ScheduleMeeting.fromJson(data as Map<String, dynamic>);
      if (updated.id != meetingId ||
          updated.status != status ||
          updated.teacherRefId != current.teacherRefId ||
          updated.studentRefId != current.studentRefId) {
        throw const FormatException(
          'No se pudo verificar el estado de la cita.',
        );
      }
      return true;
    } on NetworkException {
      // Una escritura sin respuesta puede haberse guardado; consultar antes de repetir.
      final actual = await read();
      if (actual.status == status) return true;
      rethrow;
    }
  }
}
