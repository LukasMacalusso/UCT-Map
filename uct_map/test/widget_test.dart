import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/presentation/screens/map/map_screen.dart';
import 'package:uct_map/main.dart';
import 'helpers/mock_mapbox_platform.dart';

class _OkRepo implements AuthRepository {
  @override
  Future<AuthLoginResult> login(
      {required String email, required String password}) async {
    return AuthLoginResult(userId: 'u-test', email: email, token: jwt(email));
  }

  static String jwt(String email) {
    String b64(Object o) => base64Encode(utf8.encode(jsonEncode(o)))
        .replaceAll('+', '-')
        .replaceAll('/', '_')
        .replaceAll('=', '');
    final exp =
        DateTime.now().add(const Duration(minutes: 30)).millisecondsSinceEpoch ~/
            1000;
    return "${b64({'alg': 'none'})}.${b64({'sub': 'u-test', 'email': email, 'exp': exp, 'iss': 'https://identity-api', 'aud': 'api-gateway'})}.x";
  }
}

void main() {
  testWidgets('Smoke test de inicio de la aplicación UCT Map', (WidgetTester tester) async {
    setupMockMapboxPlatform();
    await tester.pumpWidget(UctMapApp(authRepository: _OkRepo()));
    await tester.pump();

    // Verificar que los destinos del navbar estén presentes.
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Objetos'), findsOneWidget);
    expect(find.text('Reportes'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    // Con sesión, el mapa interactivo se muestra.
    await ApiClientProvider.session.signInReal(
      AuthLoginResult(
          userId: 'u-test',
          email: 'test@alu.uct.cl',
          token: _OkRepo.jwt('test@alu.uct.cl')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);

    await ApiClientProvider.session.signOut();
  });
}
