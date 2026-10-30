import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/updates/app_update_prompt.dart';

void main() {
  const channel = MethodChannel('de.ffuf.in_app_update/methods');
  late List<String> calls;
  late Map<String, dynamic> info;
  setUp(() {
    calls = [];
    info = {
      'updateAvailability': 2,
      'immediateAllowed': false,
      'flexibleAllowed': true,
      'availableVersionCode': 25,
      'installStatus': 0,
      'packageName': 'com.jaydeo.travplanner',
      'updatePriority': 0,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return call.method == 'checkForUpdate' ? info : null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  Future<void> open(WidgetTester tester) async {
    final key = GlobalKey<ScaffoldMessengerState>();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: key,
        builder: (_, child) =>
            AppUpdatePrompt(messengerKey: key, child: child!),
        home: const Scaffold(body: Text('Explore Trav')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('download and restart require separate consent', (tester) async {
    await open(tester);
    expect(calls, ['checkForUpdate']);
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(calls, ['checkForUpdate', 'startFlexibleUpdate']);
    expect(find.text('Explore Trav'), findsOneWidget);
    await tester.tap(find.text('Restart'));
    await tester.pumpAndSettle();
    expect(calls.last, 'completeFlexibleUpdate');
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  testWidgets('recovers downloaded update', (tester) async {
    info['installStatus'] = 11;
    await open(tester);
    expect(find.text('Restart'), findsOneWidget);
    expect(calls, ['checkForUpdate']);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  testWidgets('offline or sideloaded app remains usable', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'ERROR_API_NOT_AVAILABLE'),
        );
    await open(tester);
    expect(find.text('Explore Trav'), findsOneWidget);
    expect(find.text('Update'), findsNothing);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  testWidgets('unsupported platform does not call plugin', (tester) async {
    await open(tester);
    expect(calls, isEmpty);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  testWidgets('no prompt without an available update', (tester) async {
    info['updateAvailability'] = 1;
    await open(tester);
    expect(find.text('Update'), findsNothing);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
