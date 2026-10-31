import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_client_provider.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../domain/entities/office_hour.dart';
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
  }) async {
    try {
      final uri = _config.uri(path, query);
      final response = body == null
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
    final uri = _config.uri(ApiEndpoints.scheduleProfessors);
    try {
      final res = await _client.get(uri).timeout(_config.timeout);
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((p) => Professor.fromJson(p))
              .toList();
        }
      }
      throw ApiException.fromResponse(res.statusCode, res.body);
    } on http.ClientException {
      return fallbackProfessors;
    } on TimeoutException {
      return fallbackProfessors;
    }
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
  Future<List<ScheduleMeeting>> getMyMeetings() async {
    final user = ApiClientProvider.session.currentUser;
    if (user == null) throw const UnauthorizedException();
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day).toIso8601String();
    final to = DateTime(now.year, now.month, now.day + 60).toIso8601String();
    final teacher = user.role.toShortString() == 'profesor';
    final data = await _request(
      teacher
          ? '/api/schedule/meetings'
          : '/api/schedule/students/${user.id}/meetings',
      query: {'from': from, 'to': to, if (teacher) 'teacherId': user.id},
    );
    final items = teacher ? data as List : data['meetings'] as List;
    return items
        .map((m) => ScheduleMeeting.fromJson(m as Map<String, dynamic>))
        .toList();
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
    throw UnsupportedError(
      'Schedule aún no ofrece cambios de estado de citas.',
    );
  }
  // Profesores de ejemplo para ver la funcionalidad sin red o con servicios apagados.
  static const List<Professor> fallbackProfessors = [
    Professor(
      id: 'prof-1',
      name: 'Dr. Roberto González',
      department: 'Ingeniería de Software',
      office: 'Oficina 304 - Edificio Central',
      email: 'rgonzalez@uct.cl',
      officeHours: [
        OfficeHour(
          id: 'oh-1',
          teacherRefId: 'prof-1',
          dayOfWeek: 2,
          startTime: '10:00',
          endTime: '12:00',
        ),
      ],
    ),
    Professor(
      id: 'prof-2',
      name: 'Dra. Marcela Soto',
      department: 'Ciencias de la Computación',
      office: 'Oficina 210 - Edificio C',
      email: 'msoto@uct.cl',
      officeHours: [
        OfficeHour(
          id: 'oh-2',
          teacherRefId: 'prof-2',
          dayOfWeek: 4,
          startTime: '14:30',
          endTime: '16:30',
        ),
      ],
    ),
    Professor(
      id: 'prof-3',
      name: 'Mg. Carlos Peña',
      department: 'Redes y Telecomunicaciones',
      office: 'Oficina 105 - Laboratorios',
      email: 'cpena@uct.cl',
      officeHours: [
        OfficeHour(
          id: 'oh-3',
          teacherRefId: 'prof-3',
          dayOfWeek: 3,
          startTime: '09:00',
          endTime: '11:00',
        ),
      ],
    ),
  ];
}
