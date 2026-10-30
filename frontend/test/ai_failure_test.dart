import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'package:trav_planner/features/ai/data/models/ai_response_model.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';

class FailedAI extends AIApi {
  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
    Map<String, double>? location,
  }) async => const AIResponseModel(
    success: false,
    content: 'AI is temporarily unavailable.',
    agent: 'test',
    data: {},
    metadata: {},
  );
}

void main() {
  testWidgets('A blocked provider response is shown as an error with retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AISearchPage(api: FailedAI())),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Plan Paris');
    await tester.ensureVisible(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('AI request failed'));
    expect(find.text('AI request failed'), findsOneWidget);
    expect(find.text('Your AI travel companion'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
