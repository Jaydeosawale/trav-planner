import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppStorage {
  AppStorage._();

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static const String _accessTokenKey = "access_token";
  static const String _refreshTokenKey = "refresh_token";

  // ==========================================================
  // Access Token
  // ==========================================================

  static Future<void> saveAccessToken(
    String token,
  ) async {
    await _storage.write(
      key: _accessTokenKey,
      value: token,
    );
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  // ==========================================================
  // Refresh Token
  // ==========================================================

  static Future<void> saveRefreshToken(
    String token,
  ) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
    );
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(
      key: _refreshTokenKey,
    );
  }

  // ==========================================================
  // Clear Authentication
  // ==========================================================

  static Future<void> clearTokens() async {
    await _storage.delete(
      key: _accessTokenKey,
    );

    await _storage.delete(
      key: _refreshTokenKey,
    );
  }

  // ==========================================================
  // Clear Everything
  // ==========================================================

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}