import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/core/network/api_endpoints.dart';
import 'package:uct_map/data/models/campus_location_dto.dart';
import 'package:uct_map/data/models/campus_model.dart';
import 'package:uct_map/presentation/screens/search/search_screen.dart';
import 'package:uct_map/presentation/widgets/app_navigation_bar.dart';

import 'session_fixture.dart' as roles;
import 'test_fonts.dart' show loadUiFonts;

void main() {
  group('Cámara', () {
    final base = {
      'id': 'campus',
      'name': 'Campus',
      'latitude': -38.7,
      'longitude': -72.6,
    };
    test('cámara ausente es distinta de cero explícito', () {
      final absent = CampusModel.fromJson(base);
      expect(absent.zoom, isNull);
      expect(absent.pitch, isNull);
      expect(absent.bearing, isNull);
      final zero = CampusModel.fromJson({
        ...base,
        'zoom': 0,
        'pitch': 0,
        'bearing': 0,
      });
      expect(zero.zoom, 0);
      expect(zero.pitch, 0);
      expect(zero.bearing, 0);
      expect(zero.toJson()['pitch'], 0);
    });
    test('cámara conserva límites válidos y rechaza valores no numéricos o fuera de rango', () {
      final camera = CampusModel.fromJson({
        ...base,
        'zoom': 22,
        'pitch': 85,
        'bearing': -180,
      });
      expect(camera.zoom, 22);
      expect(camera.pitch, 85);
      expect(camera.bearing, -180);
      for (final field in [
        {'zoom': 23},
        {'pitch': 86},
        {'bearing': 181},
        {'zoom': '18'},
        {'pitch': double.nan},
      ]) {
        expect(
          () => CampusModel.fromJson({...base, ...field}),
          throwsFormatException,
        );
      }
    });
  });

  group('Ubicación', () {
    test(
      'ubicación Campus conserva coordenadas y servicios reales de metadata',
      () {
        Map<String, dynamic> payload(Object? services) => {
          'id': 'building',
          'name': 'Edificio real',
          'location': {'latitude': -38.7359, 'longitude': -72.6171},
          'metadata': {
            'campusId': 'campus',
            'floorsCount': 2,
            'openTime': '08:00:00',
            'closeTime': '20:00:00',
            'services': services,
          },
        };
        final location = BuildingLocationDto.fromJson(
          payload('Consultas, Biblioteca'),
        );
        expect(location.services, ['Consultas', 'Biblioteca']);
        expect(location.location.latitude, -38.7359);
        expect(location.campusId, 'campus');
        expect(BuildingLocationDto.fromJson(payload(['Consultas'])).services, [
          'Consultas',
        ]);
        expect(
          () => BuildingLocationDto.fromJson(payload(12)),
          throwsFormatException,
        );
        final malformed = payload('Consultas');
        malformed['location'] = {};
        expect(
          () => BuildingLocationDto.fromJson(malformed),
          throwsA(isA<TypeError>()),
        );
      },
    );
  });

  group('Filtros y vista', () {
    setUpAll(() async {
      await loadUiFonts();
    });
    testWidgets('captura auxiliar de campus y filtros UCT', (tester) async {
      debugDisableShadows = false;
      await tester.binding.setSurfaceSize(const Size(430, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = SessionController(storage: roles.MemoryStorage());
      await session.ready;
      ApiClientProvider.initialize(
        session,
        innerClient: MockClient(
          (r) async => http.Response(
            jsonEncode(switch (r.url.path) {
              ApiEndpoints.campusList => [
                {'id': 'campus', 'name': 'Campus Pruebas Fork'},
              ],
              ApiEndpoints.campusCategories => [
                {
                  'id': 'category',
                  'name': 'Consultas Fork',
                  'icon': 'school',
                  'description': '',
                },
              ],
              _ => [],
            }),
            200,
          ),
        ),
      );
      const key = ValueKey('capture');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF003865),
              primary: const Color(0xFF003865),
            ),
          ),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Búsqueda'),
                backgroundColor: const Color(0xFF003865),
                foregroundColor: Colors.white,
              ),
              body: const SearchScreen(),
              bottomNavigationBar: AppNavigationBar(
                currentTab: 1,
                onSelectTab: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Filtrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Consultas Fork').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
  });
}
