import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingObject {
  const PendingObject({
    required this.title,
    required this.structureId,
    this.id,
  });
  final String title;
  final String structureId;
  final String? id;
  Map<String, Object?> toJson() => {
    'title': title,
    'structureId': structureId,
    'id': id,
  };
}

abstract class PendingObjectStorage {
  Future<PendingObject?> read(String userId);
  Future<void> save(String userId, PendingObject item);
  Future<void> clear(String userId);
}

class SecurePendingObjectStorage implements PendingObjectStorage {
  const SecurePendingObjectStorage();
  static const _storage = FlutterSecureStorage();
  String _key(String userId) =>
      'uct.pending-object.${Uri.encodeComponent(userId)}';
  @override
  Future<PendingObject?> read(String userId) async {
    final raw = await _storage.read(key: _key(userId));
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return PendingObject(
      title: data['title'] as String,
      structureId: data['structureId'] as String,
      id: data['id'] as String?,
    );
  }

  @override
  Future<void> save(String userId, PendingObject item) =>
      _storage.write(key: _key(userId), value: jsonEncode(item.toJson()));
  @override
  Future<void> clear(String userId) => _storage.delete(key: _key(userId));
}
