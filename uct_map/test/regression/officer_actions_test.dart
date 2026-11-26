import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/datasources/lost_objects_remote_ds.dart';
import 'package:uct_map/data/datasources/reports_remote_ds.dart';
import 'package:uct_map/data/repositories/lost_objects_repository_impl.dart';
import 'package:uct_map/data/repositories/reports_repository_impl.dart';
import 'package:uct_map/presentation/screens/lost_objects/lost_objects_screen.dart';
import 'package:uct_map/presentation/screens/tickets/tickets_screen.dart';

import 'session_fixture.dart' as roles;

void main() {
  for (final role in [
    'ObjectsOfficer',
    'ComplaintsOfficer',
    'Student',
    'Teacher',
    'Admin',
  ]) {
    testWidgets('$role solo ve las acciones de gestión de su rol', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(900, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = await roles.signIn(role);
      var patches = 0;
      var status = 'Pending';
      var missingId = false;
      final client = MockClient((request) async {
        if (request.method == 'PATCH') {
          patches++;
          status = 'Resolved';
          return http.Response('', 204);
        }
        final objects = request.url.path.contains('lost-objects');
        return http.Response(
          jsonEncode({
            'items': [
              objects
                  ? {
                      if (!missingId) 'id': 'object-id',
                      'title': 'Objeto con ID',
                      'description': 'Descripción de prueba',
                      'status': status,
                      'photoUrl': '',
                      'structureId': 'structure',
                    }
                  : {
                      'id': 'report-id',
                      'structureRefId': 'structure',
                      'ticketType': 0,
                      'isActive': true,
                      'reportedAt': '2026-11-01T12:00:00Z',
                    },
            ],
            'totalCount': 1,
            'page': 1,
            'pageSize': 10,
            'totalPages': 1,
          }),
          200,
        );
      });
      ApiClientProvider.initialize(session, innerClient: client);
      await tester.pumpWidget(
        MaterialApp(
          home: TicketsScreen(
            repository: ReportsRepositoryImpl(
              remoteDataSource: ReportsRemoteDataSource(client: client),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Cambiar Estado'),
        role == 'ComplaintsOfficer' ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LostObjectsScreen(
            repository: LostObjectsRepositoryImpl(
              remoteDataSource: LostObjectsRemoteDataSource(client: client),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Cambiar Estado'),
        role == 'ObjectsOfficer' ? findsOneWidget : findsNothing,
      );
      if (role == 'ObjectsOfficer') {
        await tester.tap(find.text('Cambiar Estado'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Resuelto').last);
        await tester.pumpAndSettle();
        expect(patches, 1);
        expect(find.text('Estado: Resuelto'), findsOneWidget);
        missingId = true;
        await tester.pumpWidget(
          MaterialApp(
            home: LostObjectsScreen(
              key: const ValueKey('missing-id'),
              repository: LostObjectsRepositoryImpl(
                remoteDataSource: LostObjectsRemoteDataSource(client: client),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'Cambiar Estado'),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.textContaining('backend no devuelve el ID'),
          findsOneWidget,
        );
        expect(patches, 1);
      } else {
        expect(patches, 0);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
  }
}
