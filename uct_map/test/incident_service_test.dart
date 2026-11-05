import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/core/network/api_config.dart';
import 'package:uct_map/data/datasources/incident_remote_ds.dart';
import 'package:uct_map/domain/entities/lost_item.dart';
import 'package:uct_map/domain/entities/report.dart';

void main() {
  group('Incident Service Domain & Datasource Tests', () {
    test('Report y LostItem serializan y deserializan campos de MongoDB', () {
      final reportJson = {
        'idTicket': 'ticket-999',
        'title': 'Gotera en techo',
        'description': 'Filtración de agua en pasillo',
        'idStructure': 'Edificio A',
        'campus': 'Campus San Francisco',
        'idUsuario': 'user-123',
        'dateReport': '2026-09-20T12:00:00.000Z',
        'status': 'EnRevision',
        'pictureUri': 'https://storage.uct.cl/test.jpg',
      };

      final report = Report.fromJson(reportJson);
      expect(report.id, 'ticket-999');
      expect(report.title, 'Gotera en techo');
      expect(report.currentStatus, ReportStatus.enRevision);
      expect(report.imageUrl, 'https://storage.uct.cl/test.jpg');

      final lostItemJson = {
        'idTicket': 'tk-lost-1',
        'ticketNumber': 'TK-2026-001',
        'title': 'Mochila negra',
        'description': 'Olvidada en biblioteca',
        'category': 'Mochilas',
        'campus': 'Campus San Juan Pablo II',
        'idStructure': 'Biblioteca Central',
        'idUsuario': 'estudiante-1',
        'dateReport': '2026-09-21T09:00:00.000Z',
        'status': 'Publicado',
      };

      final item = LostItem.fromJson(lostItemJson);
      expect(item.id, 'tk-lost-1');
      expect(item.ticketNumber, 'TK-2026-001');
      expect(item.category, 'Mochilas');
      expect(item.currentStatus, LostItemStatus.publicado);
    });

    test(
      'IncidentRemoteDataSource obtiene lista de reportes con filtro',
      () async {
        final mockResponse = [
          {
            'id': 'rep-1',
            'title': 'Luz quemada',
            'description': 'Pasillo oscuro',
            'location': 'Piso 2',
            'campus': 'Campus San Francisco',
            'reportedBy': 'Juan',
            'reportedAt': '2026-09-21T10:00:00.000Z',
            'currentStatus': 'reportado',
            'statusHistory': [],
          },
        ];

        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['campus'], 'Campus San Francisco');
          return http.Response(jsonEncode(mockResponse), 200);
        });

        final ds = IncidentRemoteDataSource(
          client: mockClient,
          config: ApiConfig(baseUrl: 'http://localhost:5052'),
        );

        final reports = await ds.getReports(campus: 'Campus San Francisco');
        expect(reports.length, 1);
        expect(reports.first.title, 'Luz quemada');
      },
    );

    test(
      'IncidentRemoteDataSource activa fallback ante error de red',
      () async {
        final mockClient = MockClient((request) async {
          throw http.ClientException('Gateway down');
        });

        final ds = IncidentRemoteDataSource(client: mockClient);
        final items = await ds.getLostItems();

        expect(items.isNotEmpty, isTrue);
        expect(
          items.any(
            (i) =>
                i.title.contains('Calculadora') ||
                i.title.contains('Audífonos') ||
                i.title.contains('Tarjeta'),
          ),
          isTrue,
        );
      },
    );
  });
}
