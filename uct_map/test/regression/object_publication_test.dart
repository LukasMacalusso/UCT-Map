import 'package:uct_map/core/config/env_config.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/application/contributions/object_publication.dart';
import 'package:uct_map/core/network/api_exception.dart';
import 'package:uct_map/data/models/lost_object_dto.dart';
import 'package:uct_map/data/models/report_dto.dart';
import 'package:uct_map/data/storage/pending_object_storage.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/entities/lost_object.dart';
import 'package:uct_map/domain/entities/ticket.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/domain/repositories/lost_objects_repository.dart';
import 'package:uct_map/domain/repositories/reports_repository.dart';

class Storage implements TokenStorage {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> save(String value) async {}
  @override
  Future<void> clear() async {}
}

class Pending implements PendingObjectStorage {
  final values = <String, PendingObject>{};
  @override
  Future<PendingObject?> read(String userId) async => values[userId];
  @override
  Future<void> save(String userId, PendingObject item) async {
    values[userId] = item;
  }

  @override
  Future<void> clear(String userId) async {
    values.remove(userId);
  }
}

class Objects implements LostObjectsRepository {
  int calls = 0;
  bool timeout = false;
  @override
  Future<CreateLostObjectResponse> createLostObject(
    CreateLostObjectDto dto,
  ) async {
    calls++;
    if (timeout) throw const NetworkException();
    return const CreateLostObjectResponse(id: 'object');
  }

  @override
  Future<LostObject> getLostObjectById(String id) async => LostObject(
    id: id,
    title: 'Objeto de prueba',
    description: 'Descripción',
    status: LostObjectStatus.pending,
    photoUrl: 'https://example.com/photo.jpg',
    structureId: location,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const location = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';
const dto = CreateLostObjectDto(
  title: 'Objeto de prueba',
  description: 'Descripción',
  photoUrl: 'https://example.com/photo.jpg',
  structureId: location,
);

class Reports implements ReportsRepository {
  int calls = 0;
  bool loseResponse = false;
  bool linked = false;
  @override
  Future<PaginatedReportsResponse> getReports({
    ReportFilterParams? filter,
  }) async {
    expect(filter!.userRefId, 'student');
    expect(filter.lostObjectId, 'object');
    return PaginatedReportsResponse(
      items: linked
          ? [
              Ticket(
                id: 'report',
                userRefId: 'student',
                structureRefId: location,
                ticketType: TicketStatus.pending,
                isActive: true,
                reportedAt: DateTime(2026),
                lostObjectId: 'object',
              ),
            ]
          : [],
      totalCount: linked ? 1 : 0,
      page: 1,
      pageSize: 10,
      totalPages: linked ? 1 : 0,
    );
  }

  @override
  Future<CreateReportResponse> createReport(CreateReportDto dto) async {
    calls++;
    linked = true;
    expect(dto.lostObjectId, 'object');
    if (loseResponse) throw const NetworkException();
    return const CreateReportResponse(id: 'report');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SessionController session;
  late Pending storage;
  late Objects objects;
  late Reports reports;
  late ObjectPublication publication;
  Future<void> login(String userId) async {
    String enc(Object v) =>
        base64Url.encode(utf8.encode(jsonEncode(v))).replaceAll('=', '');
    await session.signInReal(
      AuthLoginResult(
        userId: userId,
        email: '$userId@uct.cl',
        token:
            '${enc({'alg': 'none'})}.${enc({'sub': userId, 'email': '$userId@uct.cl', 'role': 'Student', 'iss': EnvConfig.jwtIssuer, 'aud': EnvConfig.jwtAudience, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test',
      ),
    );
  }

  setUp(() async {
    session = SessionController(storage: Storage());
    await session.ready;
    await login('student');
    storage = Pending();
    objects = Objects();
    reports = Reports();
    publication = ObjectPublication(
      objects: objects,
      reports: reports,
      session: session,
      storage: storage,
    );
  });
  tearDown(() => session.dispose());
  test('alta y vínculo se completan una sola vez', () async {
    expect(await publication.publish(dto), 'object');
    expect(objects.calls, 1);
    expect(reports.calls, 1);
    expect(storage.values, isEmpty);
  });
  test('respuesta perdida del vínculo se reconcilia sin duplicar objeto ni reporte', () async {
    reports.loseResponse = true;
    await expectLater(
      publication.publish(dto),
      throwsA(isA<PendingObjectPublication>()),
    );
    final pending = storage.values['student']!;
    expect(pending.id, 'object');
    expect(await publication.resume(pending), 'object');
    expect(objects.calls, 1);
    expect(reports.calls, 1);
    expect(storage.values, isEmpty);
  });
  test(
    'alta incierta impide un segundo POST incluso tras reabrir el flujo',
    () async {
      objects.timeout = true;
      await expectLater(
        publication.publish(dto),
        throwsA(isA<PendingObjectPublication>()),
      );
      final reopened = ObjectPublication(
        objects: objects,
        reports: reports,
        session: session,
        storage: storage,
      );
      await expectLater(
        reopened.publish(dto),
        throwsA(isA<PendingObjectPublication>()),
      );
      expect(objects.calls, 1);
      expect(reports.calls, 0);
      expect(storage.values['student']!.id, isNull);
    },
  );
  test(
    'otra cuenta no recupera una operación pendiente de la primera',
    () async {
      reports.loseResponse = true;
      await expectLater(
        publication.publish(dto),
        throwsA(isA<PendingObjectPublication>()),
      );
      final pending = storage.values['student']!;
      await session.signOut();
      await login('other');
      await expectLater(
        publication.resume(pending),
        throwsA(isA<PendingObjectPublication>()),
      );
      expect(reports.calls, 1);
      expect(storage.values['student'], same(pending));
    },
  );
}
