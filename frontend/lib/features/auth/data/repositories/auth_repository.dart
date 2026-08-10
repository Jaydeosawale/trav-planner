import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/storage/app_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
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
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );

      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<UserModel>> getCurrentUser() async {
  try {
    final response = await ApiClient.dio.get(
      '/auth/me',
    );

    return ApiResponse<UserModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UserModel.fromJson(
        json as Map<String, dynamic>,
      ),
    );
  } catch (e) {
    return ApiResponse<UserModel>(
      success: false,
      error: e.toString(),
    );
  }
}

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
        data: {
          'refresh_token': refreshToken,
        },
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

        if (newRefreshToken != null &&
            newRefreshToken.isNotEmpty) {
          await AppStorage.saveRefreshToken(
            newRefreshToken,
          );
        }
      }

      return apiResponse;
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await AppStorage.clearTokens();
  }

  Future<bool> hasStoredSession() async {
    final token = await AppStorage.getAccessToken();

    return token != null && token.isNotEmpty;
  }
}