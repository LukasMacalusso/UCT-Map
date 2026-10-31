import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/data/services/walking_directions.dart';
import 'package:uct_map/domain/entities/building.dart';

void main() {
  test('routes to coordinates of a campus service', () async {
    final service = WalkingDirections(
      token: 'token',
      client: MockClient((request) async {
        expect(request.url.path, contains('-72.52,-38.72;-72.53,-38.73'));
        return http.Response(
          '{"code":"Ok","routes":[{"distance":100,"duration":60,"geometry":{"type":"LineString","coordinates":[[-72.52,-38.72],[-72.53,-38.73]]}}]}',
          200,
        );
      }),
    );
    final route = await service.routeBetweenCoordinates(
      -38.72,
      -72.52,
      -38.73,
      -72.53,
    );
    expect(route.coordinates.last, [-72.53, -38.73]);
    service.dispose();
  });
  const a = Building(
    id: 'a',
    campusId: 'c',
    name: 'A',
    floorsCount: 1,
    latitude: -38.7,
    longitude: -72.5,
  );
  const b = Building(
    id: 'b',
    campusId: 'c',
    name: 'B',
    floorsCount: 1,
    latitude: -38.71,
    longitude: -72.51,
  );

  test('parses walking route and sends longitude first', () async {
    final service = WalkingDirections(
      token: 'token',
      client: MockClient((request) async {
        expect(request.url.path, contains('-72.5,-38.7;-72.51,-38.71'));
        expect(request.url.queryParameters['geometries'], 'geojson');
        return http.Response(
          '{"code":"Ok","routes":[{"distance":120,"duration":90,"geometry":{"type":"LineString","coordinates":[[-72.5,-38.7],[-72.51,-38.71]]}}]}',
          200,
        );
      }),
    );
    final route = await service.route(a, b);
    expect(route.distance, 120);
    expect(route.duration, 90);
    expect(route.coordinates.length, 2);
    service.dispose();
  });

  test('reports no route and rejected tokens', () async {
    for (final response in [
      http.Response('{"code":"NoRoute","routes":[]}', 200),
      http.Response('', 401),
    ]) {
      final service = WalkingDirections(
        token: 'token',
        client: MockClient((_) async => response),
      );
      await expectLater(
        service.route(a, b),
        throwsA(isA<DirectionsException>()),
      );
      service.dispose();
    }
  });

  test('routes from current coordinates to the selected building', () async {
    final service = WalkingDirections(
      token: 'token',
      client: MockClient((request) async {
        expect(request.url.path, contains('-72.52,-38.72;-72.51,-38.71'));
        return http.Response(
          '{"code":"Ok","routes":[{"distance":120,"duration":90,"geometry":{"type":"LineString","coordinates":[[-72.52,-38.72],[-72.51,-38.71]]}}]}',
          200,
        );
      }),
    );
    final route = await service.routeFromCoordinates(-38.72, -72.52, b);
    expect(route.distance, 120);
    expect(route.coordinates.first, [-72.52, -38.72]);
    service.dispose();
  });

  test('rejects identical buildings without a network request', () async {
    final service = WalkingDirections(
      token: 'token',
      client: MockClient((_) async => throw StateError('unexpected request')),
    );
    await expectLater(service.route(a, a), throwsA(isA<DirectionsException>()));
    service.dispose();
  });
}
