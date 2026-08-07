import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

import 'environment.dart';

class ApiConfig {
  ApiConfig._();

  /// Change only this IP when developing on a physical device.
  static const String _devMachineIp = "10.102.215.97";

  static String get baseUrl {
    switch (AppEnvironment.current) {
      case Environment.production:
        return "https://api.travplanner.com/api/v1";

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

    if (Platform.isAndroid) {
      // Emulator
      return "http://$_devMachineIp:8000/api/v1";
    }

    if (Platform.isIOS) {
      return "http://$_devMachineIp:8000/api/v1";
    }

    if (Platform.isMacOS) {
      return "http://127.0.0.1:8000/api/v1";
    }

    if (Platform.isWindows) {
      return "http://127.0.0.1:8000/api/v1";
    }

    if (Platform.isLinux) {
      return "http://127.0.0.1:8000/api/v1";
    }

    return "http://127.0.0.1:8000/api/v1";
  }
}