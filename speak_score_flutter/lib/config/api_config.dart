import 'dart:io';

class ApiConfig {
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8080/api';
  static const String _iosSimulatorUrl = 'http://localhost:8080/api';

  static String get baseUrl {
    if (Platform.isAndroid) {
      return _androidEmulatorUrl;
    } else if (Platform.isIOS) {
      return _iosSimulatorUrl;
    }
    return _androidEmulatorUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
