import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/storage/app_storage.dart';
import 'package:trav_planner/features/auth/presentation/pages/reset_password_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final stored = <String, String>{};
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  setUp(() {
    stored.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final arguments = Map<String, dynamic>.from(call.arguments as Map);
          switch (call.method) {
            case 'write':
              stored[arguments['key'] as String] = arguments['value'] as String;
              return null;
            case 'read':
              return stored[arguments['key']];
            case 'delete':
              stored.remove(arguments['key']);
              return null;
            case 'deleteAll':
              stored.clear();
              return null;
          }
          return null;
        });
  });
  test(
    'Remember me controls persistence and logout clears both stores',
    () async {
      await AppStorage.configureSession(rememberMe: true);
      await AppStorage.saveAccessToken('persistent-access');
      await AppStorage.saveRefreshToken('persistent-refresh');
      expect(stored['access_token'], 'persistent-access');
      await AppStorage.configureSession(rememberMe: false);
      expect(stored, isEmpty);
      await AppStorage.saveAccessToken('session-access');
      await AppStorage.saveRefreshToken('session-refresh');
      expect(stored, isEmpty);
      expect(await AppStorage.getAccessToken(), 'session-access');
      expect(await AppStorage.getRefreshToken(), 'session-refresh');
      await AppStorage.clearTokens();
      expect(await AppStorage.getAccessToken(), isNull);
      expect(await AppStorage.getRefreshToken(), isNull);
    },
  );
  testWidgets('Reset rejects mismatched passwords before sending', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ResetPasswordPage(token: 'test-token')),
    );
    await tester.enterText(find.byType(TextField).at(0), 'LongEnough123');
    await tester.enterText(find.byType(TextField).at(1), 'Different123');
    await tester.tap(find.text('Save new password'));
    await tester.pump();
    expect(find.text('Your passwords do not match.'), findsOneWidget);
    expect(find.text('Saving…'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
