import 'package:flutter/material.dart';

import '../screens/map/map_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/lost_objects/lost_objects_screen.dart';
import '../../data/repositories/lost_objects_repository_impl.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/tickets/tickets_screen.dart';
import '../../data/datasources/reports_remote_ds.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/login/session_required_view.dart';
import '../../application/session/session_controller.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/authenticated_client.dart';
import '../../data/datasources/incident_remote_ds.dart';
import '../widgets/uct_logo.dart';
import '../widgets/custom_drawer.dart';
import '../../domain/entities/campus.dart';
import '../screens/map/widgets/campus_search_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  /// Sesión compartida de la aplicación: la misma para todas las pantallas.
  late SessionController _session;
  final _selectedCampus = ValueNotifier<Campus?>(null);
  var _mapScreenKey = GlobalKey<MapScreenState>();
  bool? _lastAuthenticated;
  bool _didReadInitialArgs = false;
  late final AuthenticatedClient _apiClient;

  final List<String> _titles = const [
    'Mapa del Campus',
    'Búsqueda',
    'Objetos Perdidos',
    'Reportes de Incidencias',
    'Mi Perfil',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _session = ApiClientProvider.session;
    ApiClientProvider.initialize(_session);
    _apiClient = ApiClientProvider.defaultClient;
    _session.addListener(_sessionChanged);
    _session.ready.then((_) {
      if (mounted) setState(() {});
    });
  }

  void _sessionChanged() {
    if (mounted)
      setState(() {
        final authenticated = _session.isAuthenticated;
        if (_lastAuthenticated != authenticated) {
          _lastAuthenticated = authenticated;
          _mapScreenKey = GlobalKey<MapScreenState>();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didReadInitialArgs) {
      _didReadInitialArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < _titles.length) {
        _currentIndex = args;
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showSearchResult(CampusSearchResult result) {
    _onTabTapped(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _mapScreenKey.currentState?.showSearchResult(result);
    });
  }

  @override
  void dispose() {
    // El cliente y la sesión son compartidos: no se cierran aquí.
    _session.removeListener(_sessionChanged);
    _selectedCampus.dispose();
    super.dispose();
  }

  Widget _protected(Widget child) =>
      SessionRequiredView(embedded: true, builder: (_) => child);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> screens = [
      MapScreen(key: _mapScreenKey, selectedCampus: _selectedCampus),
      SearchScreen(
        onExploreMap: () => _onTabTapped(0),
        selectedCampus: _selectedCampus,
        onResult: _showSearchResult,
      ),
      _protected(
        LostObjectsScreen(
          repository: LostObjectsRepositoryImpl(),
          showAppBar: false,
        ),
      ),
      _protected(
        TicketsScreen(
          repository: ReportsRepositoryImpl(
            remoteDataSource: ReportsRemoteDataSource(
              client: _apiClient,
              tokenProvider: () => _session.token,
            ),
          ),
          showAppBar: false,
        ),
      ),
      ProfileScreen(
        session: _session,
        onNavigateToTab: _onTabTapped,
        onLogout: () async {
          var message = 'Sesión cerrada correctamente';
          try {
            await _session.signOut();
          } catch (_) {
            message = 'Sesión cerrada, pero no se pudo borrar el token local.';
          }
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) {
            return InkWell(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: UctLogo(height: 36, width: 36),
              ),
            );
          },
        ),
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => _onTabTapped(4),
              child: Tooltip(
                message: 'Ver Perfil del Estudiante',
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _currentIndex == 4
                          ? theme.colorScheme.secondary
                          : Colors.white.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      color: Color(0xFF003865),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: CustomDrawer(
        currentIndex: _currentIndex,
        onSelectTab: _onTabTapped,
      ),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Objetos',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
