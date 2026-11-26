import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/application/incidents/incident_deletion.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/repositories/reports_repository_impl.dart';
import 'package:uct_map/data/repositories/lost_objects_repository_impl.dart';
import 'package:uct_map/presentation/widgets/delete_incident_button.dart';

import 'session_fixture.dart' show MemoryStorage, account;

void main() {
  for (final role in [
    'Student',
    'Teacher',
    'Admin',
    'ObjectsOfficer',
    'ComplaintsOfficer',
  ]) {
    for (final object in [true, false]) {
      testWidgets(
        '$role borrado ${object ? 'objeto' : 'incidencia'} respeta área y confirmación',
        (tester) async {
          final session = SessionController(storage: MemoryStorage());
          await session.ready;
          await account(session, 'owner', role);
          final calls = <String>[];
          ApiClientProvider.initialize(
            session,
            innerClient: MockClient((req) async {
              calls.add('${req.method} ${req.url.path}');
              if (req.method == 'DELETE') return http.Response('', 204);
              if (req.url.path.endsWith('/lost-objects/object'))
                return http.Response(
                  jsonEncode({
                    'id': 'object',
                    'title': 'Objeto prueba',
                    'description': 'Real',
                    'structureId': 'place',
                    'status': 0,
                  }),
                  200,
                );
              if (req.url.path.endsWith('/reports/report'))
                return http.Response(
                  jsonEncode({
                    'id': 'report',
                    'userRefId': 'owner',
                    'structureRefId': 'place',
                    'ticketType': 0,
                    'isActive': true,
                    'complaintDetails': {
                      'title': 'Incidencia prueba',
                      'description': 'Real',
                      'status': 0,
                    },
                  }),
                  200,
                );
              if (req.url.path.endsWith('/reports'))
                return http.Response(
                  jsonEncode({
                    'items': [],
                    'page': 1,
                    'pageSize': 1,
                    'totalCount': 0,
                    'totalPages': 0,
                  }),
                  200,
                );
              return http.Response('{}', 404);
            }),
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DeleteIncidentButton(
                  id: object ? 'object' : 'report',
                  title: 'Registro prueba',
                  locationId: 'place',
                  object: object,
                ),
              ),
            ),
          );
          final allowed = object
              ? role == 'ObjectsOfficer'
              : role == 'ComplaintsOfficer';
          final label = object ? 'Eliminar objeto' : 'Eliminar incidencia';
          expect(find.text(label), allowed ? findsOneWidget : findsNothing);
          if (allowed) {
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Cancelar'));
            await tester.pumpAndSettle();
            expect(calls.where((s) => s.startsWith('DELETE')), isEmpty);
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
            await tester.pumpAndSettle();
            expect(calls.where((s) => s.startsWith('DELETE')).length, 1);
          } else {
            expect(calls, isEmpty);
          }
          await tester.pumpWidget(const SizedBox());
          session.dispose();
          ApiClientProvider.reset();
        },
      );
    }
  }
  for (final object in [true, false]) {
    testWidgets(
      'bloquea vínculo y cambio de sesión en ${object ? 'objeto' : 'incidencia'}',
      (tester) async {
        final session = SessionController(storage: MemoryStorage());
        await session.ready;
        await account(
          session,
          'owner',
          object ? 'ObjectsOfficer' : 'ComplaintsOfficer',
        );
        var linked = true;
        var switchUser = false;
        var deletes = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((req) async {
            if (req.method == 'DELETE') {
              deletes++;
              return http.Response('', 204);
            }
            if (switchUser) await account(session, 'other', 'Student');
            if (req.url.path.endsWith('/lost-objects/id'))
              return http.Response(
                jsonEncode({
                  'id': 'id',
                  'title': 'Objeto',
                  'structureId': 'place',
                  'status': 0,
                }),
                200,
              );
            if (req.url.path.endsWith('/reports/id'))
              return http.Response(
                jsonEncode({
                  'id': 'id',
                  'structureRefId': 'place',
                  'userRefId': 'owner',
                  'complaintDetails': {'title': 'Incidencia'},
                  if (linked) 'lostObjectId': 'object',
                }),
                200,
              );
            return http.Response(
              jsonEncode({
                'items': linked
                    ? [
                        {'id': 'link', 'lostObjectId': 'id'},
                      ]
                    : [],
                'totalCount': linked ? 1 : 0,
                'page': 1,
                'totalPages': 1,
                'pageSize': 1,
              }),
              200,
            );
          }),
        );
        final deletion = IncidentDeletion(
          session: session,
          reports: ReportsRepositoryImpl(),
          objects: LostObjectsRepositoryImpl(),
        );
        Future<void> run() =>
            object ? deletion.deleteObject('id') : deletion.deleteReport('id');
        await expectLater(run(), throwsStateError);
        expect(deletes, 0);
        linked = false;
        switchUser = true;
        await expectLater(run(), throwsA(anything));
        expect(deletes, 0);
        session.dispose();
        ApiClientProvider.reset();
      },
    );
  }
}
