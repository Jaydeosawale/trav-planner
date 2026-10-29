import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/network/api_client.dart';
import 'package:trav_planner/core/network/api_response.dart';
import 'package:trav_planner/core/storage/app_storage.dart';
import 'package:trav_planner/features/auth/data/models/user_model.dart';
import 'package:trav_planner/features/auth/data/repositories/auth_repository.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';

class OfflineAuth implements AuthRepository {
  int checks = 0, logouts = 0;
  int? status;
  @override
  Future<bool> hasStoredSession() async => true;
  @override
  Future<ApiResponse<UserModel>> getCurrentUser() async {
    checks++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return ApiResponse(
      success: false,
      statusCode: status,
      error: 'unavailable',
    );
  }

  @override
  Future<void> logout() async {
    logouts++;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class SessionAdapter implements HttpClientAdapter {
  int refreshes = 0, originals = 0;
  int refreshStatus = 200;
  bool alwaysReject = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    if (o.path == '/auth/refresh') {
      refreshes++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return ResponseBody.fromString(
        '{"data":{"access_token":"new","refresh_token":"rotated"}}',
        refreshStatus,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    originals++;
    final ok = o.headers['Authorization'] == 'Bearer new' && !alwaysReject;
    return ResponseBody.fromString(
      '{}',
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
    await AppStorage.configureSession(rememberMe: false);
    await AppStorage.saveAccessToken('old');
    await AppStorage.saveRefreshToken('refresh');
  });
  test(
    'Outage preserves credentials; concurrent startup uses one profile request',
    () async {
      final repo = OfflineAuth();
      final c = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(c.dispose);
      await Future.wait([
        c.read(authProvider.notifier).checkSession(),
        c.read(authProvider.notifier).checkSession(),
      ]);
      expect(repo.checks, 1);
      expect(repo.logouts, 0);
      expect(c.read(authProvider).status, AuthStatus.unavailable);
      expect(await AppStorage.getAccessToken(), 'old');
      repo.status = 401;
      await c.read(authProvider.notifier).checkSession();
      expect(repo.logouts, 1);
      expect(c.read(authProvider).status, AuthStatus.unauthenticated);
    },
  );
  test(
    'Simultaneous expired requests share refresh and retry each once',
    () async {
      final adapter = SessionAdapter();
      final client = ApiClient.create(baseUrl: 'https://test.invalid')
        ..httpClientAdapter = adapter;
      addTearDown(() => client.close(force: true));
      final replies = await Future.wait([
        client.get('/one'),
        client.get('/two'),
      ]);
      expect(replies.map((r) => r.statusCode), [200, 200]);
      expect(adapter.refreshes, 1);
      expect(adapter.originals, 4);
      expect(await AppStorage.getRefreshToken(), 'rotated');
    },
  );
  test(
    'Refresh server failure keeps both tokens; rejected retry cannot loop',
    () async {
      final adapter = SessionAdapter()..refreshStatus = 503;
      final client = ApiClient.create(baseUrl: 'https://test.invalid')
        ..httpClientAdapter = adapter;
      addTearDown(() => client.close(force: true));
      await expectLater(client.get('/one'), throwsA(isA<DioException>()));
      expect(await AppStorage.getAccessToken(), 'old');
      expect(await AppStorage.getRefreshToken(), 'refresh');
      adapter.refreshStatus = 200;
      adapter.alwaysReject = true;
      await expectLater(
        client.get('/one').timeout(const Duration(seconds: 2)),
        throwsA(isA<DioException>()),
      );
      expect(adapter.refreshes, 2);
      expect(adapter.originals, 3);
    },
  );
}
