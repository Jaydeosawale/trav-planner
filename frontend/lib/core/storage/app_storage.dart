import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  AppStorage._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _accessTokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";

  static bool _persistent = true;
  static final Map<String, String> _session = {};

  static Future<void> configureSession({required bool rememberMe}) async {
    await clearTokens();
    _persistent = rememberMe;
  }

  // ==========================================================
  // Access Token
  // ==========================================================

  static Future<void> saveAccessToken(String token) async {
    if (_persistent) {
      await _storage.write(key: _accessTokenKey, value: token);
    } else {
      _session[_accessTokenKey] = token;
    }
  }

  static Future<String?> getAccessToken() async {
    return _persistent
        ? _storage.read(key: _accessTokenKey)
        : _session[_accessTokenKey];
  }

  // ==========================================================
  // Refresh Token
  // ==========================================================

  static Future<void> saveRefreshToken(String token) async {
    if (_persistent) {
      await _storage.write(key: _refreshTokenKey, value: token);
    } else {
      _session[_refreshTokenKey] = token;
    }
  }

  static Future<String?> getRefreshToken() async {
    return _persistent
        ? _storage.read(key: _refreshTokenKey)
        : _session[_refreshTokenKey];
  }

  // ==========================================================
  // Clear Authentication
  // ==========================================================

  static Future<void> clearTokens() async {
    _session.clear();
    await _storage.delete(key: _accessTokenKey);

    await _storage.delete(key: _refreshTokenKey);
  }

  // ==========================================================
  // Clear Everything
  // ==========================================================

  static Future<void> clear() async {
    _session.clear();
    await _storage.deleteAll();
  }
}
