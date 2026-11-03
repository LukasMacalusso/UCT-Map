import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'core/config/env_config.dart';
import 'core/config/oauth_config.dart';
import 'core/navigation/app_routes.dart';
import 'data/repositories/oauth_pkce_repository.dart';
import 'domain/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.init();
  MapboxOptions.setAccessToken(const String.fromEnvironment('ACCESS_TOKEN'));
  OAuthConfig? oauthConfig;
  try {
    oauthConfig = OAuthConfig.fromEnvironment();
  } on FormatException {
    debugPrint(
      'Configuración de acceso externo inválida; acceso deshabilitado.',
    );
  }
  runApp(UctMapApp(oauthConfig: oauthConfig));
}

class UctMapApp extends StatelessWidget {
  const UctMapApp({
    super.key,
    this.authRepository,
    this.oauthRepository,
    this.oauthConfig,
    this.oauthSessionExchange,
  });

  /// Auth del login; por defecto usa el backend real.
  final AuthRepository? authRepository;
  final OAuthRepository? oauthRepository;
  final OAuthConfig? oauthConfig;
  final OAuthSessionExchange? oauthSessionExchange;

  @override
  Widget build(BuildContext context) {
    final externalLogin =
        oauthRepository ??
        (oauthConfig != null && oauthSessionExchange != null
            ? OAuthPkceRepository(
                client: OAuthPkceClient(config: oauthConfig!),
                exchangeSession: oauthSessionExchange!,
              )
            : null);
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
      onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(
        settings,
        authRepository: authRepository,
        oauthRepository: externalLogin,
      ),
    );
  }
}
