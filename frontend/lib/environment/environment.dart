
import 'package:flutter/foundation.dart';

class Environment {

  static String getBaseUrl() {

    String configuredBaseUrl = const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: '',
    );

    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
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