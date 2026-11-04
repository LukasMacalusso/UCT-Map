import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/presentation/screens/admin/admin_campus_screen.dart';
import 'package:uct_map/presentation/screens/login/access_denied_view.dart';
import 'package:uct_map/domain/entities/campus.dart';
import 'package:uct_map/presentation/screens/admin/admin_buildings_screen.dart';
import 'package:uct_map/presentation/screens/admin/admin_structures_screen.dart';
import 'package:uct_map/presentation/screens/admin/admin_categories_screen.dart';
import 'package:uct_map/presentation/screens/admin/admin_rooms_screen.dart';
import 'package:uct_map/presentation/screens/admin/campus_location_picker_screen.dart';

class _Storage implements TokenStorage {
  String? value;
  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<String?> read() async => value;
  @override
  Future<void> save(String token) async {
    value = token;
  }
}

void main() {
  test('prioriza Juan Pablo II y conserva la selección posterior', () {
    const sanFrancisco = Campus(
      id: 'sf',
      name: 'San Francisco',
      address: '',
      latitude: 0,
      longitude: 0,
    );
    const juanPablo = Campus(
      id: 'jp',
      name: 'Campus San Juan Pablo II',
      address: '',
      latitude: 0,
      longitude: 0,
    );
    expect(preferredAdminCampus([sanFrancisco, juanPablo])?.id, 'jp');
    expect(
      preferredAdminCampus([sanFrancisco, juanPablo], previousId: 'sf')?.id,
      'sf',
    );
    expect(preferredAdminCampus([]), isNull);
  });
  for (final role in [
    'Student',
    'Teacher',
    'ObjectsOfficer',
    'ComplaintsOfficer',
  ]) {
    testWidgets(
      '$role no puede abrir administración de campus ni solicitar datos',
      (tester) async {
        final session = SessionController(storage: _Storage());
        await session.ready;
        final payload = {
          'sub': 'user-fixture',
          'email': 'demo@uct.cl',
          'role': role,
          'exp':
              DateTime.now()
                  .add(const Duration(hours: 1))
                  .millisecondsSinceEpoch ~/
              1000,
          'iss': 'https://identity-api',
          'aud': 'api-gateway',
        };
        String enc(Object json) =>
            base64Url.encode(utf8.encode(jsonEncode(json)));
        await session.signInReal(
          AuthLoginResult(
            userId: 'user-fixture',
            email: 'demo@uct.cl',
            token: '${enc({'alg': 'HS256'})}.${enc(payload)}.signature',
          ),
        );
        var calls = 0;
        ApiClientProvider.reset(
          session: session,
          mockClient: MockClient((_) async {
            calls++;
            return http.Response('[]', 200);
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            onGenerateRoute: AppRoutes.onGenerateRoute,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.manageCampus,
                  ),
                  child: const Text('Abrir administración de campus'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Abrir administración de campus'));
        await tester.pumpAndSettle();
        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(calls, 0);
        await tester.pumpWidget(const MaterialApp(home: AdminCampusScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(calls, 0);
        const campus = Campus(
          id: 'jp2',
          name: 'Campus San Juan Pablo II',
          address: '',
          latitude: 0,
          longitude: 0,
        );
        await tester.pumpWidget(
          const MaterialApp(home: AdminStructuresScreen(campus: campus)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(calls, 0);
        await tester.pumpWidget(
          const MaterialApp(home: AdminCategoriesScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(calls, 0);
        await tester.pumpWidget(
          const MaterialApp(
            home: AdminRoomsScreen(
              buildingId: 'building',
              buildingName: 'Edificio',
              floorsCount: 2,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(calls, 0);
        await tester.pumpWidget(
          const MaterialApp(
            home: CampusLocationPickerScreen(
              latitude: 0,
              longitude: 0,
              title: 'Ubicación',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(calls, 0);
        await tester.pumpWidget(
          const MaterialApp(
            home: AdminBuildingsScreen(
              campus: Campus(
                id: 'jp2',
                name: 'Campus San Juan Pablo II',
                address: '',
                latitude: 0,
                longitude: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(calls, 0);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
  }
}
