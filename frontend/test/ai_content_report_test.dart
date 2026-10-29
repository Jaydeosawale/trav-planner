import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/widgets/ai_content_report_button.dart';

void main() {
  testWidgets(
    'Report stays in app, retains a failed draft and confirms only successful submission',
    (tester) async {
      var fail = true;
      Map<String, dynamic>? submitted;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (fail) {
              handler.reject(DioException(requestOptions: options));
              return;
            }
            submitted = Map<String, dynamic>.from(options.data);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {'id': 'report1', 'status': 'pending'},
              ),
            );
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AIContentReportButton(
              sourceKind: 'chat',
              referenceId: 'session1',
              client: dio,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Report AI content'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Unsafe advice');
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Report could not be sent'), findsOneWidget);
      expect(find.text('Report received'), findsNothing);
      expect(find.text('Unsafe advice'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();
      expect(submitted, {
        'source_kind': 'chat',
        'reference_id': 'session1',
        'reason': 'unsafe',
        'details': 'Unsafe advice',
      });
      expect(find.text('Report received'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
