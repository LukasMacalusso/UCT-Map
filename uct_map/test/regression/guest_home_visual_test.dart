import 'test_fonts.dart' show loadUiFonts;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/presentation/screens/home/home_screen.dart';

import 'session_fixture.dart' as roles;

void main() {
  setUpAll(() async {
    await loadUiFonts();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('Inicio informativo invitado a 390 px y texto $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final session = SessionController(storage: roles.MemoryStorage());
      await session.ready;
      ApiClientProvider.initialize(session);
      const key = ValueKey('guest-capture');
      debugDisableShadows = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF003865),
              primary: const Color(0xFF003865),
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const RepaintBoundary(key: key, child: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Conoce tu campus\ncon UCT Map'), findsOneWidget);
      expect(find.text('Explora sin una cuenta'), findsOneWidget);
      expect(find.text('Próxima consulta'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Cuando inicies sesión'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Cuando inicies sesión').hitTestable(), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
      debugDisableShadows = true;
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    });
  }
  testWidgets(
    'contenido de invitado no sustituye inicio autenticado de otros roles',
    (tester) async {
      final session = await roles.signIn('Admin');
      ApiClientProvider.initialize(session);
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Explora sin una cuenta'), findsNothing);
      expect(find.text('Gestionar usuarios'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      ApiClientProvider.reset();
      session.dispose();
    },
  );
}
