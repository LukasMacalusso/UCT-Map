import 'package:flutter/material.dart';

import '../screens/map/map_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/lost_found/lost_found_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/login/auth_required_view.dart';
import '../../application/session/session_controller.dart';
import '../../core/network/api_client_provider.dart';
import '../../core/network/authenticated_client.dart';
import '../../data/datasources/incident_remote_ds.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/uct_logo.dart';
import '../widgets/custom_drawer.dart';

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
  bool _didReadInitialArgs = false;
  late final AuthenticatedClient _apiClient;

  static const _protectedTabs = [2, 3, 4];

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
    if (mounted) setState(() {});
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

  @override
  void dispose() {
    // El cliente y la sesión son compartidos: no se cierran aquí.
    _session.removeListener(_sessionChanged);
    super.dispose();
  }

  Future<void> _openLogin(String section) async {
    final result = await Navigator.pushNamed(
      context,
      '/login',
      arguments: section,
    );
    if (result is Map && result['ok'] == true && mounted) {
      final userId = (result['userId'] ?? '').toString();
      final email = (result['email'] ?? '').toString();
      final token = (result['token'] ?? '').toString();
      if (userId.isEmpty || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar sesión.')),
        );
        return;
      }
      try {
        await _session.signInReal(
          AuthLoginResult(userId: userId, email: email, token: token),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo iniciar sesión.')),
        );
        return;
      }
      if (mounted) setState(() {});
    }
  }

  Widget _protected(int index, Widget real, String section) {
    if (_session.isAuthenticated || !_protectedTabs.contains(index)) {
      return real;
    }
    return AuthRequiredView(onLogin: () => _openLogin(section));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearchTab = _currentIndex == 1;

    final List<Widget> screens = [
      MapScreen(key: ValueKey(_session.isAuthenticated)),
      SearchScreen(onExploreMap: () => _onTabTapped(0)),
      _protected(
        2,
        LostFoundScreen(
          onNavigateToTab: _onTabTapped,
          incidentRepository: IncidentRemoteDataSource(client: _apiClient),
        ),
        'Objetos perdidos',
      ),
      _protected(
        3,
        ReportsScreen(
          onNavigateToTab: _onTabTapped,
          incidentRepository: IncidentRemoteDataSource(client: _apiClient),
        ),
        'Reportes de incidencias',
      ),
      _protected(
        4,
        ProfileScreen(
          session: _session,
          onNavigateToTab: _onTabTapped,
          onLogout: () async {
            try {
              await _session.signOut();
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Sesión cerrada, pero no se pudo borrar el token local.',
                  ),
                ),
              );
            }
            if (mounted) setState(() {});
          },
        ),
        'Perfil del usuario',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        // En la pantalla de buscar sale solo el botón hamburguesa a la izquierda para categorías
        leading: isSearchTab
            ? Builder(
                builder: (context) {
                  return IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    tooltip: 'Categorías',
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  );
                },
              )
            : Builder(
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
        // En la pantalla de buscar no sale el avatar de la derecha
        actions: isSearchTab
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () => _onTabTapped(4), // Ir al perfil
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
