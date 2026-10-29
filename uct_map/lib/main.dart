import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/config/env_config.dart';
import 'core/navigation/app_routes.dart';
import 'domain/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.init();
  MapboxOptions.setAccessToken(const String.fromEnvironment('ACCESS_TOKEN'));
  runApp(const UctMapApp());
}

class UctMapApp extends StatelessWidget {
  const UctMapApp({super.key, this.authRepository});

  /// Auth del login; por defecto usa el backend real.
  final AuthRepository? authRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCT Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003865), // Azul institucional UCT
          primary: const Color(0xFF003865),
          secondary: const Color(0xFFEAA221), // Tono secundario dorado/cálido
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      initialRoute: AppRoutes.initial,
      onGenerateRoute: (settings) =>
          AppRoutes.onGenerateRoute(settings, authRepository: authRepository),
    );
  }
}
