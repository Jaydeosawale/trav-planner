import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/admin/presentation/pages/admin_ai_routing_panel.dart';

void main() {
  testWidgets(
    'Admin changes order, disables a provider, saves and retains failed changes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic> config = {
        'enabled': true,
        'provider_order': ['openai', 'groq', 'gemini'],
        'providers': {
          'openai': {
            'configured': true,
            'reason': 'Free access must be verified before activation',
          },
          'groq': {'configured': true, 'reason': 'Free tier only'},
          'gemini': {'configured': true, 'reason': 'Free tier only'},
        },
      };
      bool fail = false;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/usage')) {
              handler.resolve(
                Response(requestOptions: options, data: {'providers': []}),
              );
              return;
            }
            if (options.method == 'PUT') {
              if (fail) {
                handler.reject(DioException(requestOptions: options));
                return;
              }
              config = {...config, ...Map<String, dynamic>.from(options.data)};
            }
            handler.resolve(Response(requestOptions: options, data: config));
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AdminAIRoutingPanel(client: dio),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1. OPENAI'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Later').first);
      await tester.pumpAndSettle();
      expect(find.text('1. GROQ'), findsOneWidget);
      await tester.ensureVisible(find.text('3. GEMINI'));
      await tester.tap(find.text('3. GEMINI'));
      await tester.ensureVisible(find.text('Save provider settings'));
      await tester.tap(find.text('Save provider settings'));
      await tester.pumpAndSettle();
      expect(config['provider_order'], ['groq', 'openai']);
      expect(find.text('Provider settings saved.'), findsOneWidget);
      fail = true;
      await tester.ensureVisible(find.text('AI available to users'));
      await tester.tap(find.byType(Switch));
      await tester.ensureVisible(find.text('Save provider settings'));
      await tester.tap(find.text('Save provider settings'));
      await tester.pumpAndSettle();
      expect(
        find.text('Couldn’t save. Your changes are kept—try again.'),
        findsOneWidget,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
