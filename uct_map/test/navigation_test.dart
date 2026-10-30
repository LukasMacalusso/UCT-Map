import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/core/navigation/app_routes.dart';
import 'package:uct_map/domain/entities/lost_item.dart';
import 'package:uct_map/domain/entities/report.dart';
import 'package:uct_map/main.dart';
import 'package:uct_map/presentation/navigation/main_navigation_screen.dart';
import 'package:uct_map/presentation/screens/home/home_screen.dart';
import 'package:uct_map/presentation/screens/login/login_page.dart';
import 'package:uct_map/presentation/screens/login/session_required_view.dart';
import 'package:uct_map/presentation/screens/reports/reports_screen.dart';
import 'package:uct_map/presentation/screens/profile/saved_places_screen.dart';
import 'package:uct_map/presentation/screens/profile/profile_settings_screen.dart';
import 'package:uct_map/presentation/screens/profile/my_reports_screen.dart';
import 'package:uct_map/presentation/screens/profile/my_lost_items_screen.dart';
import 'package:uct_map/presentation/screens/lost_found/lost_found_screen.dart';
import 'package:uct_map/presentation/screens/lost_found/lost_item_detail_screen.dart';
import 'package:uct_map/presentation/screens/professors/professors_screen.dart';
import 'package:uct_map/presentation/screens/reports/report_detail_screen.dart';
import 'helpers/mock_mapbox_platform.dart';

void main() {
  setUpAll(setupMockMapboxPlatform);

  group('AppRoutes tests', () {
    testWidgets('AppRoutes.onGenerateRoute resuelve todas las rutas nombradas',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final BuildContext testContext = tester.element(find.byType(SizedBox));

      // 1. Ruta / (MainNavigationScreen)
      final mainRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.initial),
      ) as MaterialPageRoute;
      expect(mainRoute.builder(testContext),
          isA<MainNavigationScreen>());

      // 2. Ruta / con argumentos de pestaña
      final mainTabRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.initial, arguments: 2),
      ) as MaterialPageRoute;
      final mainTabWidget =
          mainTabRoute.builder(testContext)
              as MainNavigationScreen;
      expect(mainTabWidget.initialIndex, 2);

      // 3. Ruta /home
      final homeRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.home),
      ) as MaterialPageRoute;
      expect(homeRoute.builder(testContext),
          isA<HomeScreen>());

      // 4. Ruta /professors: exige sesión
      final profRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.professors),
      ) as MaterialPageRoute;
      expect(profRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<ProfessorsScreen>()));

      // 5. Ruta /reports (con AppBar)
      final reportsRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.reports),
      ) as MaterialPageRoute;
      expect(reportsRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<ReportsScreen>()));

      // 6. Ruta /reports/detail con entidad Report
      final sampleReport = mockReports[0];
      final reportDetailRoute = AppRoutes.onGenerateRoute(
        RouteSettings(name: AppRoutes.reportDetail, arguments: sampleReport),
      ) as MaterialPageRoute;
      expect(reportDetailRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<ReportDetailScreen>()));

      // 7. Ruta /lost-found (con AppBar)
      final lostRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.lostFound),
      ) as MaterialPageRoute;
      expect(lostRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<LostFoundScreen>()));

      // 8. Ruta /lost-found/detail con entidad LostItem
      final sampleItem = mockLostItems[0];
      final lostDetailRoute = AppRoutes.onGenerateRoute(
        RouteSettings(name: AppRoutes.lostItemDetail, arguments: sampleItem),
      ) as MaterialPageRoute;
      expect(lostDetailRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<LostItemDetailScreen>()));

      // 9. Ruta /saved-places
      final savedRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.savedPlaces),
      ) as MaterialPageRoute;
      expect(savedRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<SavedPlacesScreen>()));

      // 10. Ruta /my-reports
      final myRepRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.myReports),
      ) as MaterialPageRoute;
      expect(myRepRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<MyReportsScreen>()));

      // 11. Ruta /my-lost-items
      final myLostRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.myLostItems),
      ) as MaterialPageRoute;
      expect(myLostRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<MyLostItemsScreen>()));

      // 12. Ruta /profile-settings
      final settingsRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.profileSettings),
      ) as MaterialPageRoute;
      expect(settingsRoute.builder(testContext),
          anyOf(isA<SessionRequiredView>(), isA<ProfileSettingsScreen>()));

      // 13. Ruta /login
      final loginRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: AppRoutes.login),
      ) as MaterialPageRoute;
      expect(loginRoute.builder(testContext),
          isA<LoginPage>());

      // 14. Ruta no reconocida -> fallback
      final fallbackRoute = AppRoutes.onGenerateRoute(
        const RouteSettings(name: '/ruta-desconocida'),
      ) as MaterialPageRoute;
      expect(fallbackRoute.builder(testContext),
          isA<MainNavigationScreen>());
    });

    testWidgets('CustomDrawer navega a Inicio, Profesores y Vistas secundarias',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const UctMapApp());
      await tester.pumpAndSettle();

      // Abrir el drawer usando ScaffoldState
      tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
      await tester.pumpAndSettle();

      // Verificar que los accesos del Drawer estén presentes
      expect(find.text('Inicio y Accesos Rápidos'), findsOneWidget);
      expect(find.text('Directorio de Profesores'), findsOneWidget);
      expect(find.text('Lugares Guardados'), findsOneWidget);
      expect(find.text('Mis Reportes'), findsOneWidget);
      expect(find.text('Objetos Reportados'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);

      // Navegar a Directorio de Profesores desde el Drawer
      await tester.tap(find.text('Directorio de Profesores'));
      await tester.pumpAndSettle();

      expect(
        find.byType(ProfessorsScreen),
        findsOneWidget,
      );

      // Volver atrás
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('HomeScreen conecta correctamente a Mapa, Buscar y otras vistas',
        (tester) async {
      int navigatedTab = -1;
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: HomeScreen(
          onNavigateToTab: (index) {
            navigatedTab = index;
          },
        ),
      ));

      // Tocar 'Ver Mapa'
      await tester.ensureVisible(find.text('Ver Mapa'));
      await tester.tap(find.text('Ver Mapa'));
      await tester.pumpAndSettle();
      expect(navigatedTab, 0);

      // Tocar 'Buscar Salas'
      await tester.ensureVisible(find.text('Buscar Salas'));
      await tester.tap(find.text('Buscar Salas'));
      await tester.pumpAndSettle();
      expect(navigatedTab, 1);

      // Tocar 'Objetos Perdidos'
      await tester.ensureVisible(find.text('Objetos Perdidos'));
      await tester.tap(find.text('Objetos Perdidos'));
      await tester.pumpAndSettle();
      expect(navigatedTab, 2);

      // Tocar 'Reportes'
      await tester.ensureVisible(find.text('Reportes'));
      await tester.tap(find.text('Reportes'));
      await tester.pumpAndSettle();
      expect(navigatedTab, 3);

      // Tocar 'Mi Perfil'
      await tester.ensureVisible(find.text('Mi Perfil'));
      await tester.tap(find.text('Mi Perfil'));
      await tester.pumpAndSettle();
      expect(navigatedTab, 4);
    });

    testWidgets('ProfessorsScreen botón Ver en Mapa retorna tab 0',
        (tester) async {
      int targetTab = -1;
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: Scaffold(
          body: ProfessorsScreen(
            onNavigateToTab: (tab) => targetTab = tab,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Expandir el primer profesor
      await tester.tap(find.text('Dr. Roberto González'));
      await tester.pumpAndSettle();

      // Tocar 'Ver en Mapa'
      await tester.tap(find.text('Ver en Mapa'));
      await tester.pumpAndSettle();

      expect(targetTab, 0);
      expect(find.textContaining('Ubicando oficina'), findsOneWidget);
    });

    testWidgets('ReportDetailScreen botón Ver en Mapa retorna tab 0',
        (tester) async {
      int targetTab = -1;
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: ReportDetailScreen(
          report: mockReports[0],
          onNavigateToTab: (tab) => targetTab = tab,
        ),
      ));

      // Tocar icono de mapa en el AppBar
      await tester.tap(find.byIcon(Icons.map_outlined).first);
      await tester.pumpAndSettle();

      expect(targetTab, 0);
      expect(find.textContaining('Ubicando'), findsOneWidget);
    });

    testWidgets('LostItemDetailScreen botón Ver en Mapa retorna tab 0',
        (tester) async {
      int targetTab = -1;
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: LostItemDetailScreen(
          item: mockLostItems[0],
          onNavigateToTab: (tab) => targetTab = tab,
        ),
      ));

      // Tocar icono de mapa en el AppBar
      await tester.tap(find.byIcon(Icons.map_outlined).first);
      await tester.pumpAndSettle();

      expect(targetTab, 0);
      expect(find.textContaining('Ubicando'), findsOneWidget);
    });

    testWidgets('LoginPage muestra botón Volver si canPop es true',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      ctx,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text('Go Login'),
                ),
              ),
            );
          },
        ),
      ));

      await tester.tap(find.text('Go Login'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byTooltip('Volver'), findsOneWidget);

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsNothing);
    });
  });
}
