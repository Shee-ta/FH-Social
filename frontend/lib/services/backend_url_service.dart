import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/environment/environment.dart';

class BackendUrlService extends ChangeNotifier {
  static const _storageKey = 'backend_base_url';

  final FlutterSecureStorage _storage;

  BackendUrlService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  late String _baseUrl;
  String get baseUrl => _baseUrl;

  Future<void> init() async {
    final stored = await _storage.read(key: _storageKey);
    final fallback = Environment.getBaseUrl();
    _baseUrl = normalize(stored ?? fallback);
  }

  Future<void> setBaseUrl(String value) async {
    final normalized = normalize(value);
    _baseUrl = normalized;
    await _storage.write(key: _storageKey, value: normalized);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    final fallback = normalize(Environment.getBaseUrl());
    _baseUrl = fallback;
    await _storage.delete(key: _storageKey);
    notifyListeners();
  }

  static String normalize(String value) {
    final trimmed = value.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static bool isValid(String value) {
    final normalized = normalize(value);
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      return false;
    }
    if (!(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }
    if (uri.host.isEmpty) {
      return false;
    }
    return true;
  }
}
