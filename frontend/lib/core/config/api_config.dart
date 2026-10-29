import 'package:flutter/foundation.dart';

import 'environment.dart';

class ApiConfig {
  ApiConfig._();

  /// Mac's LAN IP.
  ///
  /// Used when running the application on a physical
  /// Android/iOS device.
  static const String _devMachineIp = "10.222.42.97";
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;

    switch (AppEnvironment.current) {
      case Environment.production:
        return "https://jaydeo-trav-planner-api.onrender.com/api/v1";

      case Environment.staging:
        return "https://staging-api.travplanner.com/api/v1";

      case Environment.development:
        return _developmentUrl;
    }
  }

  static String get _developmentUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api/v1";
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "http://$_devMachineIp:8000/api/v1";

      case TargetPlatform.iOS:
        return "http://$_devMachineIp:8000/api/v1";

      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return "http://127.0.0.1:8000/api/v1";
    }
  }
}

