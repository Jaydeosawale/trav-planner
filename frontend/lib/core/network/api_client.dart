import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/app_storage.dart';

class ApiClient {
  ApiClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        // ==========================================================
        // Add access token to every authenticated request
        // ==========================================================

        onRequest: (options, handler) async {
          final token = await AppStorage.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $token';
          }

          handler.next(options);
        },

        // ==========================================================
        // Handle expired access token
        // ==========================================================

        onError: (error, handler) async {
          // Only handle 401 Unauthorized.
          if (error.response?.statusCode != 401) {
            handler.next(error);
            return;
          }

          final path = error.requestOptions.path;

          // ========================================================
          // Authentication endpoints must NOT trigger refresh.
          // ========================================================

          final isAuthRequest =
              path.endsWith('/auth/login') ||
              path.endsWith('/auth/register') ||
              path.endsWith('/auth/refresh');

          if (isAuthRequest) {
            handler.next(error);
            return;
          }

          // ========================================================
          // Get refresh token
          // ========================================================

          final refreshToken =
              await AppStorage.getRefreshToken();

          if (refreshToken == null ||
              refreshToken.isEmpty) {
            await AppStorage.clearTokens();
            handler.next(error);
            return;
          }

          try {
            // ======================================================
            // Request new access token
            // ======================================================

            final refreshResponse = await dio.post(
              '/auth/refresh',
              data: {
                'refresh_token': refreshToken,
              },
              options: Options(
                headers: {
                  'Authorization': null,
                },
              ),
            );

            // ======================================================
            // Extract token response
            // ======================================================

            final responseData =
                refreshResponse.data as Map<String, dynamic>;

            final data =
                responseData['data']
                    as Map<String, dynamic>?;

            final newAccessToken =
                data?['access_token'] as String?;

            final newRefreshToken =
                data?['refresh_token'] as String?;

            // ======================================================
            // Refresh failed / invalid response
            // ======================================================

            if (newAccessToken == null ||
                newAccessToken.isEmpty) {
              await AppStorage.clearTokens();
              handler.next(error);
              return;
            }

            // ======================================================
            // Save new access token
            // ======================================================

            await AppStorage.saveAccessToken(
              newAccessToken,
            );

            // ======================================================
            // Save rotated refresh token if backend returned one
            // ======================================================

            if (newRefreshToken != null &&
                newRefreshToken.isNotEmpty) {
              await AppStorage.saveRefreshToken(
                newRefreshToken,
              );
            }

            // ======================================================
            // Retry original request
            // ======================================================

            final requestOptions = error.requestOptions;

            requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(
              requestOptions,
            );

            handler.resolve(retryResponse);
          } catch (_) {
            // ======================================================
            // Refresh failed
            // ======================================================

            await AppStorage.clearTokens();

            handler.next(error);
          }
        },
      ),
    );
}