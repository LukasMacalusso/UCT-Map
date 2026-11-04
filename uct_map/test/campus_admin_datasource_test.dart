import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_config.dart';
import 'package:uct_map/data/datasources/campus_remote_ds.dart';

void main() {
  test(
    'Campus admin envía operaciones de escritura a rutas existentes',
    () async {
      final calls = <String>[];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path} ${request.body}');
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({...body, 'id': 'created'}), 201);
        }
        return http.Response('', 204);
      });
      final data = CampusRemoteDataSource(
        client: client,
        config: ApiConfig(baseUrl: 'http://gateway'),
      );
      const point = {'latitude': -38.7, 'longitude': -72.6};

      final campus = await data.createCampus({
        'name': 'Campus prueba',
        'address': 'Temuco',
        ...point,
        'zoom': 16,
        'pitch': 0,
        'bearing': 0,
      });
      expect(campus.id, 'created');
      await data.updateCampus('campus-1', {
        'name': 'Campus actualizado',
        'address': 'Temuco',
        ...point,
        'zoom': 16,
        'pitch': 0,
        'bearing': 0,
      });
      await data.updateCampusLocation('campus-1', -38.71, -72.61);
      await data.deleteCampus('campus-1');
      await data.createBuilding({
        'campusId': 'campus-1',
        'name': 'Biblioteca',
        'floorsCount': 2,
        ...point,
      });
      await data.updateBuildingLocation('building-1', -38.71, -72.61);
      await data.deleteBuilding('building-1');
      await data.createStructure({
        'campusId': 'campus-1',
        'name': 'Casino',
        ...point,
      });
      await data.updateStructure('structure-1', {
        'campusId': 'campus-1',
        'name': 'Casino nuevo',
        ...point,
      });
      await data.updateStructureLocation('structure-1', -38.71, -72.61);
      await data.deleteStructure('structure-1');
      await data.createRoom({
        'buildingId': 'building-1',
        'name': 'Sala 101',
        'floor': 1,
      });
      await data.updateRoom('room-1', {
        'buildingId': 'building-1',
        'name': 'Sala 102',
        'floor': 1,
      });
      await data.deleteRoom('room-1');
      await data.createCategory({
        'name': 'Servicios',
        'icon': 'place',
        'order': 0,
      });
      await data.updateCategory('category-1', {
        'name': 'Servicios',
        'icon': 'place',
        'order': 0,
      });
      await data.reorderCategories([
        {'id': 'category-1', 'order': 0},
      ]);
      await data.deleteCategory('category-1');

      expect(calls, contains(startsWith('POST /api/campus/campuses ')));
      expect(calls, contains(startsWith('PUT /api/campus/campuses/campus-1 ')));
      expect(
        calls,
        contains(startsWith('PATCH /api/campus/campuses/campus-1/location ')),
      );
      expect(calls, contains(startsWith('POST /api/campus/buildings ')));
      expect(calls, contains(startsWith('POST /api/campus/structures ')));
      expect(calls, contains(startsWith('POST /api/campus/rooms ')));
      expect(calls, contains(startsWith('POST /api/campus/categories ')));
      expect(
        calls,
        contains(startsWith('PUT /api/campus/categories/reorder ')),
      );
      expect(calls, contains(startsWith('DELETE /api/campus/rooms/room-1 ')));
    },
  );
}
