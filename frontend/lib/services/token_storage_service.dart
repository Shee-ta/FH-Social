import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _accessTokenKey = 'auth_access_token';

  final FlutterSecureStorage _storage;

  TokenStorageService()
  : _storage = const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> removeAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
