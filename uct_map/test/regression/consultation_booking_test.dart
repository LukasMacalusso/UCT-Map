import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/data/datasources/schedule_remote_ds.dart';
import 'package:uct_map/domain/entities/office_hour.dart';
import 'package:uct_map/domain/entities/professor.dart';
import 'package:uct_map/presentation/screens/professors/consultation_booking_screen.dart';

import 'session_fixture.dart' show MemoryStorage, account;

void main() {
  late SessionController session;
  var created = false;
  setUp(() {
    created = false;
  });
  tearDown(() {
    if (created) session.dispose();
    ApiClientProvider.reset();
  });

  Future<void> showBooking(
    WidgetTester tester,
    Future<http.Response> Function(http.Request) handler, {
    Future<http.Response> Function(http.Request)? availability,
    double textScale = 1,
  }) async {
    session = SessionController(storage: MemoryStorage());
    created = true;
    await account(session, 'student', 'Student');
    ApiClientProvider.initialize(session);
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    final professor = Professor(
      id: 'teacher',
      name: 'Docente de prueba',
      email: 'docente@uct.cl',
      department: '',
      office: '',
      officeHours: [
        OfficeHour(
          id: 'h',
          teacherRefId: 'teacher',
          structureRefId: 'place',
          dayOfWeek: next.weekday,
          startTime: '09:00',
          endTime: '10:00',
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF003865),
            primary: const Color(0xFF003865),
            secondary: const Color(0xFFEAA221),
          ),
        ),
        home: ConsultationBookingScreen(
          professor: professor,
          locations: const {'place': 'Sala de consulta'},
          repository: ScheduleRemoteDataSource(
            client: MockClient((request) async {
              if (request.method == 'GET') {
                if (availability != null) return availability(request);
                return http.Response(
                  request.url.path.contains('/students/')
                      ? '{"meetings":[]}'
                      : '[]',
                  200,
                );
              }
              return handler(request);
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Solicitar cita'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Solicitar cita'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'duración seleccionada gobierna intervalos y payload de la reserva',
    (tester) async {
      var posts = 0;
      await showBooking(tester, (request) async {
        posts++;
        expect(jsonDecode(request.body)['durationMinutes'], 60);
        expect(
          DateTime.parse(jsonDecode(request.body)['scheduledAt'])
              .toLocal()
              .hour,
          9,
        );
        return http.Response('{"message":"occupied"}', 409);
      });
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('booking-duration')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('booking-duration')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('60 minutos').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, '09:30'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Solicitar cita'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Solicitar cita'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Solicitar cita'));
      await tester.pumpAndSettle();
      expect(posts, 1);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      created = false;
    },
  );

  testWidgets('conflicto conserva fecha/hora y permite elegir otra franja', (
    tester,
  ) async {
    var posts = 0;
    await showBooking(tester, (request) async {
      posts++;
      expect(jsonDecode(request.body)['durationMinutes'], 30);
      return http.Response('{"message":"occupied"}', 409);
    });
    await tester.tap(find.text('Solicitar cita'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.textContaining('acaba de ocuparse'), findsOneWidget);
    expect(find.text('Agendar consulta'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '09:00'), findsNothing);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '09:30'))
          .selected,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    created = false;
  });

  testWidgets('envío en curso bloquea doble solicitud y navegación de vuelta', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var posts = 0;
    await showBooking(tester, (_) {
      posts++;
      return response.future;
    });
    await tester.tap(find.text('Solicitar cita'));
    await tester.pump();
    expect(posts, 1);
    expect(find.text('Enviando solicitud…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);
    response.complete(http.Response('{}', 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('no está disponible'), findsOneWidget);
    expect(find.text('Solicitar cita'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    created = false;
  });

  testWidgets('una respuesta incierta consulta la agenda antes de reenviar', (
    tester,
  ) async {
    var posts = 0;
    var lookups = 0;
    await showBooking(
      tester,
      (request) async {
        posts++;
        throw http.ClientException('Conexión interrumpida');
      },
      availability: (request) async {
        if (!request.url.path.contains('/students/'))
          return http.Response('[]', 200);
        lookups++;
        if (lookups == 2) return http.Response('{}', 503);
        return http.Response('{"studentRefId":"student","meetings":[]}', 200);
      },
    );
    await tester.tap(find.text('Solicitar cita'));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(lookups, 2);
    final check = find.text('Comprobar solicitud');
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(lookups, 4);
    expect(find.text('Solicitar cita'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    created = false;
  });

  testWidgets('al cerrar sesión retira la reserva y no envía peticiones', (
    tester,
  ) async {
    var posts = 0;
    await showBooking(tester, (_) async {
      posts++;
      return http.Response('{}', 500);
    });
    await session.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Solicitar cita'), findsNothing);
    expect(posts, 0);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    created = false;
  });

  Map<String, dynamic> occupied({
    String status = 'Pending',
    String time = '09:00:00',
    int duration = 30,
  }) {
    final now = DateTime.now();
    final date = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).toIso8601String().split('T').first;
    return {
      'teacherRefId': 'teacher',
      'studentRefId': 'other',
      'scheduledAt': DateTime.parse('${date}T$time').toUtc().toIso8601String(),
      'durationMinutes': duration,
      'status': status,
    };
  }

  for (final status in ['Pending', 'Confirmed', 'Completed', 'Cancelled']) {
    testWidgets('las franjas reservadas se ocultan según contrato: $status', (
      tester,
    ) async {
      await showBooking(
        tester,
        (_) async => http.Response('{}', 500),
        availability: (request) async {
          return http.Response(
            jsonEncode(
              request.url.path.contains('/students/')
                  ? {'meetings': []}
                  : [occupied(status: status)],
            ),
            200,
          );
        },
      );
      expect(
        find.widgetWithText(ChoiceChip, '09:00'),
        status == 'Cancelled' ? findsOneWidget : findsNothing,
      );
      expect(find.widgetWithText(ChoiceChip, '09:30'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      created = false;
    });
  }

  testWidgets(
    'solapamiento parcial ocupa todas las franjas afectadas y bloquea el envío',
    (tester) async {
      await showBooking(
        tester,
        (_) async => http.Response('{}', 500),
        availability: (request) async => http.Response(
          jsonEncode(
            request.url.path.contains('/students/')
                ? {'meetings': []}
                : [occupied(time: '09:15:00')],
          ),
          200,
        ),
      );
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.textContaining('No quedan horas libres'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      created = false;
    },
  );

  testWidgets('fallo de ocupación no ofrece horas libres inventadas', (
    tester,
  ) async {
    await showBooking(
      tester,
      (_) async => http.Response('{}', 500),
      availability: (_) async => http.Response('{}', 503),
    );
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.textContaining('No se pudo comprobar'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    created = false;
  });

  for (final (size, scale) in [
    (const Size(412, 915), 1.0),
    (const Size(1280, 900), 1.0),
    (const Size(320, 915), 2.0),
  ]) {
    testWidgets(
      'reserva se adapta a ${size.width} con texto $scale sin desbordar',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await showBooking(
          tester,
          (_) async => http.Response('{}', 500),
          textScale: scale,
        );
        expect(find.text('docente@uct.cl'), findsNothing);
        expect(find.byType(ExpansionTile), findsNothing);
        await tester.drag(find.byType(ListView).first, const Offset(0, 1500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        session.dispose();
        created = false;
      },
    );
  }
}
