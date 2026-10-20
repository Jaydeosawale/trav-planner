import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../storage/app_storage.dart';

class ApiClient {
  ApiClient._();
  static final Dio dio = create();

  static Dio create({String? baseUrl}) {
    final client = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );
    client.interceptors.add(SessionInterceptor(client));
    return client;
  }
}

/// A single refresh serves simultaneous expired requests. Transport errors never
/// erase a stored session, and an original request can only be retried once.
class SessionInterceptor extends Interceptor {
  SessionInterceptor(this.client);
  final Dio client;
  Future<String?>? _refresh;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipSession'] != true) {
      final token = await AppStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<String?> _renew() async {
    final token = await AppStorage.getRefreshToken();
    if (token == null || token.isEmpty) {
      await AppStorage.clearTokens();
      return null;
    }
    try {
      final response = await client.post(
        '/auth/refresh',
        data: {'refresh_token': token},
        options: Options(extra: {'skipSession': true}),
      );
      final data = response.data is Map ? response.data['data'] : null;
      final access = data is Map ? data['access_token'] : null;
      if (access is! String || access.isEmpty) return null;
      await AppStorage.saveAccessToken(access);
      final rotated = data['refresh_token'];
      if (rotated is String && rotated.isNotEmpty) {
        await AppStorage.saveRefreshToken(rotated);
      }
      return access;
    } on DioException catch (error) {
      if ([400, 401, 403].contains(error.response?.statusCode)) {
        await AppStorage.clearTokens();
      }
      rethrow;
    }
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    final request = error.requestOptions;
    final authRequest = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      '/auth/forgot-password',
      '/auth/reset-password',
    ].any(request.path.endsWith);
    if (error.response?.statusCode != 401 ||
        authRequest ||
        request.extra['sessionRetried'] == true) {
      handler.next(error);
      return;
    }
    try {
      final current = await AppStorage.getAccessToken();
      String? renewed;
      if (current != null &&
          current.isNotEmpty &&
          request.headers['Authorization'] != 'Bearer $current') {
        renewed = current;
      } else {
        final pending = _refresh ??= _renew();
        try {
          renewed = await pending;
        } finally {
          if (identical(_refresh, pending)) _refresh = null;
        }
      }
      if (renewed == null) {
        handler.next(error);
        return;
      }
      request.extra['sessionRetried'] = true;
      request.headers['Authorization'] = 'Bearer $renewed';
      final result = await client.fetch(request);
      handler.resolve(result);
    } on DioException catch (failure) {
      // Preserve the actual refresh/transport failure so callers can distinguish
      // an unavailable service from invalid credentials.
      handler.next(failure);
    } catch (_) {
      handler.next(error);
    }
  }
}
