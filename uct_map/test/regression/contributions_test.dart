import 'package:uct_map/core/config/env_config.dart';
import 'package:uct_map/application/contributions/user_objects.dart';
import 'package:uct_map/domain/entities/lost_object.dart';
import 'package:uct_map/domain/repositories/lost_objects_repository.dart';

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/application/contributions/user_reports.dart';
import 'package:uct_map/data/models/report_dto.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/entities/ticket.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/domain/repositories/reports_repository.dart';

class Storage implements TokenStorage {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> save(String value) async {}
  @override
  Future<void> clear() async {}
}

class Reports implements ReportsRepository {
  Reports(this.owner, {this.objectId});
  final String? objectId;
  final String owner;
  final pages = <int>[];
  @override
  Future<PaginatedReportsResponse> getReports({
    ReportFilterParams? filter,
  }) async {
    expect(filter!.userRefId, 'student');
    pages.add(filter.page);
    return PaginatedReportsResponse(
      items: [
        Ticket(
          id: 'r${filter.page}',
          lostObjectId: objectId,
          userRefId: owner,
          structureRefId: 'place',
          ticketType: TicketStatus.pending,
          isActive: true,
          reportedAt: DateTime(2026),
          complaintDetails: const ComplaintDetails(
            title: 'Incidencia real',
            description: 'Descripción real',
          ),
        ),
      ],
      page: filter.page,
      pageSize: 1,
      totalPages: 2,
      totalCount: 2,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SessionController session;
  setUp(() async {
    session = SessionController(storage: Storage());
    await session.ready;
    String enc(Object v) =>
        base64Url.encode(utf8.encode(jsonEncode(v))).replaceAll('=', '');
    await session.signInReal(
      AuthLoginResult(
        userId: 'student',
        email: 'test@uct.cl',
        token:
            '${enc({'alg': 'none'})}.${enc({'sub': 'student', 'email': 'test@uct.cl', 'role': 'Student', 'iss': EnvConfig.jwtIssuer, 'aud': EnvConfig.jwtAudience, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test',
      ),
    );
  });
  tearDown(() => session.dispose());
  test(
    'consulta todas las páginas propias sin contar solo la primera',
    () async {
      final repo = Reports('student');
      final values = await loadUserReports(repo, session);
      expect(repo.pages, [1, 2]);
      expect(values.map((v) => v.id), ['r1', 'r2']);
    },
  );
  test('rechaza respuesta de otro autor sin exponerla', () async {
    await expectLater(
      loadUserReports(Reports('other'), session),
      throwsFormatException,
    );
  });
  test(
    'objetos propios deduplican vínculos de varias páginas y usan detalle real',
    () async {
      final repo = Objects();
      final result = await loadUserObjects(
        Reports('student', objectId: 'object'),
        repo,
        session,
      );
      expect(repo.reads, ['object']);
      expect(result.items.single.id, 'object');
      expect(result.unavailable, 0);
    },
  );
}

class Objects implements LostObjectsRepository {
  final reads = <String>[];
  @override
  Future<LostObject> getLostObjectById(String id) async {
    reads.add(id);
    return LostObject(
      id: id,
      title: 'Objeto real',
      description: 'Descripción',
      status: LostObjectStatus.pending,
      photoUrl: '',
      structureId: 'place',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
