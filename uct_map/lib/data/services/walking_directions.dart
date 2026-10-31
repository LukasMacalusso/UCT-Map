import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/building.dart';

class WalkingRoute {
  const WalkingRoute(this.coordinates, this.distance, this.duration);
  final List<List<double>> coordinates;
  final double distance;
  final double duration;
}

class DirectionsException implements Exception {
  const DirectionsException(this.message);
  final String message;
}

class WalkingDirections {
  WalkingDirections({http.Client? client, String? token})
    : _client = client ?? http.Client(),
      _token = token ?? const String.fromEnvironment('ACCESS_TOKEN');

  final http.Client _client;
  final String _token;

  Future<WalkingRoute> route(Building origin, Building destination) async {
    if (origin.id == destination.id ||
        origin.campusId != destination.campusId) {
      throw const DirectionsException(
        'Selecciona dos edificios distintos del mismo campus.',
      );
    }
    return routeFromCoordinates(origin.latitude, origin.longitude, destination);
  }

  Future<WalkingRoute> routeFromCoordinates(
    double latitude,
    double longitude,
    Building destination,
  ) async {
    return routeBetweenCoordinates(
      latitude,
      longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  Future<WalkingRoute> routeBetweenCoordinates(
    double latitude,
    double longitude,
    double destinationLatitude,
    double destinationLongitude,
  ) async {
    if (_token.isEmpty) {
      throw const DirectionsException('Falta configurar el token de Mapbox.');
    }
    final uri = Uri.https(
      'api.mapbox.com',
      '/directions/v5/mapbox/walking/$longitude,$latitude;$destinationLongitude,$destinationLatitude',
      {'access_token': _token, 'geometries': 'geojson', 'overview': 'full'},
    );
    try {
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw const DirectionsException('Mapbox rechazó el token de acceso.');
      }
      if (response.statusCode != 200) {
        throw const DirectionsException(
          'No se pudo consultar el servicio de rutas.',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (json['code'] != 'Ok' || routes == null || routes.isEmpty) {
        throw const DirectionsException(
          'No se encontró un recorrido a pie hasta el destino.',
        );
      }
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = (geometry['coordinates'] as List).map((point) {
        final values = point as List;
        return [(values[0] as num).toDouble(), (values[1] as num).toDouble()];
      }).toList();
      if (geometry['type'] != 'LineString' || coordinates.length < 2) {
        throw const FormatException('Invalid route geometry');
      }
      return WalkingRoute(
        coordinates,
        (route['distance'] as num).toDouble(),
        (route['duration'] as num).toDouble(),
      );
    } on DirectionsException {
      rethrow;
    } catch (_) {
      throw const DirectionsException(
        'No se pudo obtener la ruta. Revisa tu conexión e inténtalo nuevamente.',
      );
    }
  }

  void dispose() => _client.close();
}
