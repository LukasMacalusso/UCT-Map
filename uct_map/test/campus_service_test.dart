import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_config.dart';
import 'package:uct_map/data/datasources/campus_remote_ds.dart';
import 'package:uct_map/domain/entities/campus.dart';
import 'package:uct_map/data/models/building_model.dart';

void main() {
  test('BuildingModel acepta servicios como texto del backend', () {
    final building = BuildingModel.fromJson({
      'id': 'b-1',
      'campusId': 'c-1',
      'name': 'Edificio',
      'floorsCount': 2,
      'latitude': -38.0,
      'longitude': -72.0,
      'services': 'Ascensor, Wifi',
    });
    expect(building.services, ['Ascensor', 'Wifi']);
  });
  group('Campus Service Domain & Datasource Tests', () {
    test('Campus, Building y Room serializan y deserializan correctamente', () {
      final campusJson = {
        'id': 'campus-1',
        'name': 'Campus San Francisco',
        'address': 'Manuel Montt 056',
        'coordinates': {'latitude': -38.7369, 'longitude': -72.6021},
        'buildings': [
          {
            'id': 'b-1',
            'campusId': 'campus-1',
            'name': 'Edificio C',
            'floorsCount': 3,
            'coordinates': {'latitude': -38.7369, 'longitude': -72.6021},
            'rooms': [
              {
                'id': 'r-1',
                'buildingId': 'b-1',
                'categoryId': 'cat-aula',
                'name': 'Sala C-201',
                'floor': 2,
                'number': '201',
              },
            ],
          },
        ],
      };

      final campus = Campus.fromJson(campusJson);
      expect(campus.id, 'campus-1');
      expect(campus.name, 'Campus San Francisco');
      expect(campus.latitude, -38.7369);
      expect(campus.buildings.length, 1);

      final building = campus.buildings.first;
      expect(building.name, 'Edificio C');
      expect(building.floorsCount, 3);
      expect(building.rooms.length, 1);

      final room = building.rooms.first;
      expect(room.name, 'Sala C-201');
      expect(room.floor, 2);
      expect(room.number, '201');
    });

    test(
      'CampusRemoteDataSource procesa respuesta 200 de /api/campus',
      () async {
        final mockResponse = [
          {
            'id': 'campus-test',
            'name': 'Campus de Prueba',
            'address': 'Calle Falsa 123',
            'coordinates': {'latitude': -38.7, 'longitude': -72.6},
          },
        ];

        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode(mockResponse), 200);
        });

        final ds = CampusRemoteDataSource(
          client: mockClient,
          config: ApiConfig(baseUrl: 'http://localhost:5052'),
        );

        final result = await ds.getCampuses();
        expect(result.length, 1);
        expect(result.first.name, 'Campus de Prueba');
      },
    );

    test('CampusRemoteDataSource activa fallback ante error de red', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection refused');
      });

      final ds = CampusRemoteDataSource(client: mockClient);
      final result = await ds.getCampuses();

      // Debe retornar los campus de fallback para mantener operativa la app
      expect(result.isNotEmpty, isTrue);
      expect(result.any((c) => c.name.contains('San Juan Pablo II')), isTrue);
    });
  });
}
