import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
  });
  final int currentTab;
  final ValueChanged<int> onSelectTab;
  static const _tabs = [5, 0, 1, 3, 2];

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: _tabs.contains(currentTab) ? _tabs.indexOf(currentTab) : 0,
    onDestinationSelected: (index) => onSelectTab(_tabs[index]),
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map),
        label: 'Mapa',
      ),
      NavigationDestination(icon: Icon(Icons.search), label: 'Buscar'),
      NavigationDestination(
        icon: Icon(Icons.report_problem_outlined),
        label: 'Reportes',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        label: 'Objetos',
      ),
    ],
  );
}
