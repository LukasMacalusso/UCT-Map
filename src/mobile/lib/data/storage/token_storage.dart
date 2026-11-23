import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Guarda del token JWT en almacenamiento cifrado del SO.
abstract class TokenStorage {
  Future<void> save(String token);
  Future<String?> read();
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'auth_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> save(String token) => _storage.write(key: _key, value: token);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
