import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/app_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  // ==========================================================
  // Login
  // ==========================================================

  Future<ApiResponse> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        await AppStorage.configureSession(rememberMe: rememberMe);
        final data = apiResponse.data!;

        final accessToken = data['access_token'] as String?;
        final refreshToken = data['refresh_token'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          await AppStorage.saveAccessToken(accessToken);
        }

        if (refreshToken != null && refreshToken.isNotEmpty) {
          await AppStorage.saveRefreshToken(refreshToken);
        }
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // ==========================================================
  // Register
  // ==========================================================

  Future<ApiResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/register',
        data: {'email': email, 'password': password, 'full_name': fullName},
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // ==========================================================
  // Current User
  // ==========================================================

  Future<ApiResponse<UserModel>> getCurrentUser() async {
    try {
      final response = await ApiClient.dio.get('/auth/me');

      return ApiResponse<UserModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse<UserModel>(success: false, error: e.toString());
    }
  }

  // ==========================================================
  // Current Admin
  // ==========================================================

  Future<ApiResponse<UserModel>> getCurrentAdmin() async {
    try {
      final response = await ApiClient.dio.get('/admin/me');

      return ApiResponse<UserModel>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse<UserModel>(success: false, error: e.toString());
    }
  }

  // ==========================================================
  // Refresh Token
  // ==========================================================

  Future<ApiResponse> refreshToken() async {
    try {
      final refreshToken = await AppStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        return const ApiResponse(
          success: false,
          error: 'No refresh token available.',
        );
      }

      final response = await ApiClient.dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        final data = apiResponse.data!;

        final accessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;

        if (accessToken != null && accessToken.isNotEmpty) {
          await AppStorage.saveAccessToken(accessToken);
        }

        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await AppStorage.saveRefreshToken(newRefreshToken);
        }
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse(success: false, error: e.toString());
    }
  }

  // ==========================================================
  // Logout
  // ==========================================================

  Future<void> logout() async {
    await AppStorage.clearTokens();
  }

  // ==========================================================
  // Stored Session
  // ==========================================================

  Future<bool> hasStoredSession() async {
    final token = await AppStorage.getAccessToken();

    return token != null && token.isNotEmpty;
  }

  Future<String> requestRecovery(String email) async {
    try {
      final result = await ApiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email.trim().toLowerCase()},
      );
      return result.data['message'] as String;
    } on DioException catch (error) {
      throw Exception(
        _message(
          error,
          'We could not send a recovery email. Please try again.',
        ),
      );
    }
  }

  Future<void> resetPassword(String token, String password) async {
    try {
      await ApiClient.dio.post(
        '/auth/reset-password',
        data: {'token': token, 'password': password},
      );
      await AppStorage.clearTokens();
    } on DioException catch (error) {
      throw Exception(
        _message(error, 'We could not change your password. Please try again.'),
      );
    }
  }

  static String _message(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }
}
