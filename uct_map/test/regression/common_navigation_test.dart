import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uct_map/application/session/session_controller.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/presentation/navigation/main_navigation_screen.dart';

import '../helpers/mock_mapbox_platform.dart';
import 'session_fixture.dart' as roles;

class _Observer extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

void main() {
  setUpAll(setupMockMapboxPlatform);
  for (final role in ['Student', 'Teacher', 'ObjectsOfficer', 'Guest']) {
    testWidgets(
      '$role cambia desde Inicio sin rutas nuevas y conserva búsqueda',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = role == 'Guest'
            ? SessionController(storage: roles.MemoryStorage())
            : await roles.signIn(role);
        await session.ready;
        var campusReads = 0;
        ApiClientProvider.initialize(
          session,
          innerClient: MockClient((request) async {
            if (request.url.path.endsWith('/campuses')) campusReads++;
            return http.Response(
              request.url.path.contains('/students/')
                  ? '{"studentRefId":"user","meetings":[]}'
                  : '[]',
              200,
            );
          }),
        );
        final observer = _Observer();
        await tester.pumpWidget(
          MaterialApp(
            home: const MainNavigationScreen(initialIndex: 5),
            navigatorObservers: [observer],
          ),
        );
        await tester.pumpAndSettle();
        final shell = tester.state(find.byType(MainNavigationScreen));
        final header = tester.element(find.byType(AppBar));
        await tester.tap(find.text('Buscar'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'biblioteca');
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        final reads = campusReads;
        for (final tab in [
          'Inicio',
          'Reportes',
          'Objetos',
          'Inicio',
          'Buscar',
        ]) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.state(find.byType(MainNavigationScreen)), same(shell));
          expect(tester.element(find.byType(AppBar)), same(header));
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(observer.pushes, 1);
        }
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          'biblioteca',
        );
        expect(
          campusReads,
          reads + (role == 'Guest' ? 0 : 2),
        ); // Reportes y Objetos recargan ubicaciones al activarse.
        expect(find.text('Búsqueda'), findsOneWidget);
        await tester.tap(find.text('Inicio'));
        await tester.pumpAndSettle();
        await session.signOut();
        await tester.pumpAndSettle();
        expect(find.text('Próxima consulta'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        ApiClientProvider.reset();
        session.dispose();
      },
    );
  }
}
