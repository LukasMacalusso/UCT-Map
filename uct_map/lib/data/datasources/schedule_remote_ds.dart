import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_client_provider.dart';
import '../../core/network/api_config.dart';
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
}
