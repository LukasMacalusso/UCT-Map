import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/storage/token_storage.dart';
import 'package:uct_map/domain/entities/campus.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/presentation/screens/admin/admin_buildings_screen.dart';

class _Storage implements TokenStorage {
  String? token;
  @override
  Future<void> clear() async => token = null;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> save(String value) async => token = value;
}

void main() {
  testWidgets('editar edificio conserva categoría, horarios y ubicación', (
    tester,
  ) async {
    final session = SessionController(storage: _Storage());
    await session.ready;
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value)));
    final payload = {
      'sub': 'admin',
      'email': 'admin@uct.cl',
      'role': 'Admin',
      'exp':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000,
      'iss': 'https://identity-api',
      'aud': 'api-gateway',
    };
    await session.signInReal(
      AuthLoginResult(
        userId: 'admin',
        email: 'admin@uct.cl',
        token: '${encode({'alg': 'HS256'})}.${encode(payload)}.signature',
      ),
    );
    Map<String, dynamic>? saved;
    final building = {
      'id': 'edificio',
      'campusId': 'jp2',
      'name': 'Biblioteca',
      'floorsCount': 2,
      'latitude': -38.7,
      'longitude': -72.6,
      'openTime': '08:00:00',
      'closeTime': '18:00:00',
      'services': 'WiFi',
      'categoryId': 'categoria',
    };
    ApiClientProvider.reset(
      session: session,
      mockClient: MockClient((request) async {
        if (request.method == 'PUT') {
          saved = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 204);
        }
        if (request.url.path.endsWith('/buildings/edificio/rooms'))
          return http.Response(
            jsonEncode([
              {
                'id': 'sala',
                'name': 'Sala',
                'buildingId': 'edificio',
                'floor': 2,
              },
            ]),
            200,
          );
        if (request.url.path.endsWith('/buildings/edificio'))
          return http.Response(jsonEncode(building), 200);
        if (request.url.path.endsWith('/buildings'))
          return http.Response(jsonEncode([building]), 200);
        if (request.url.path.endsWith('/categories'))
          return http.Response(
            jsonEncode([
              {
                'id': 'categoria',
                'name': 'Servicios',
                'icon': 'place',
                'description': '',
              },
            ]),
            200,
          );
        return http.Response('[]', 200);
      }),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: AdminBuildingsScreen(
          campus: Campus(
            id: 'jp2',
            name: 'Campus San Juan Pablo II',
            address: '',
            latitude: -38.7,
            longitude: -72.6,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    expect(find.text('Editar edificio'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'Biblioteca actualizada',
    );
    final save = find.text('Guardar cambios');
    final editorList = find.byType(ListView).last;
    for (var i = 0; i < 5 && save.evaluate().isEmpty; i++) {
      await tester.drag(editorList, const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(saved?['name'], 'Biblioteca actualizada');
    expect(saved?['campusId'], 'jp2');
    expect(saved?['categoryId'], 'categoria');
    expect(saved?['openTime'], '08:00:00');
    expect(saved?['closeTime'], '18:00:00');
    expect(saved?['services'], 'WiFi');
    expect(saved?['latitude'], -38.7);
    await tester.pumpWidget(const SizedBox());
    ApiClientProvider.reset();
    session.dispose();
  });
}
