
import 'package:flutter/foundation.dart';

class Environment {
  // For physical devices, pass BACKEND_URL with your Mac's LAN address:
  // flutter run --dart-define=BACKEND_URL=http://192.168.x.x:3000

  static String getBaseUrl() {

    final configuredBaseUrl = const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: '',
    ).trim();

    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl.endsWith('/')
          ? configuredBaseUrl.substring(0, configuredBaseUrl.length - 1)
          : configuredBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    // Android emulator cannot access host localhost directly.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }
}