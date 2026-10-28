import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uct_map/core/network/api_client_provider.dart';
import 'package:uct_map/domain/repositories/auth_repository.dart';
import 'package:uct_map/main.dart';

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

void _mockSecureStorage() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async => null,
  );
}

void main() {
  testWidgets('Smoke test de inicio de la aplicación UCT Map', (WidgetTester tester) async {
    _mockSecureStorage();
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

    expect(find.byType(FlutterMap), findsOneWidget);

    await ApiClientProvider.session.signOut();
  });
}
