import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'package:trav_planner/features/ai/data/models/ai_response_model.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/features/ai/presentation/widgets/plan_postcard.dart';

class ConversationAI extends AIApi {
  int messages = 0;
  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
  }) async => AIResponseModel(
    success: true,
    content: 'Reply ${++messages}: $message',
    agent: 'test',
    data: {},
    metadata: {},
  );
}

void main() {
  testWidgets('conversation keeps earlier turns during follow-up', (
    tester,
  ) async {
    final api = ConversationAI();
    await tester.pumpWidget(MaterialApp(home: AISearchPage(api: api)));
    for (final message in ['Pune museums', 'Less walking']) {
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), message);
      await tester.ensureVisible(find.byTooltip('Send message'));
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Pune museums'), findsOneWidget);
    expect(find.textContaining('Reply 1:'), findsOneWidget);
    expect(find.textContaining('Reply 2:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('illustrated plan postcard fits a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: PlanPostcard(
              destination: 'A very long destination name',
              days: 7,
              activities: 35,
            ),
          ),
        ),
      ),
    );
    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('35 stops'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('plan illustration exports as a PNG', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: RepaintBoundary(
                key: key,
                child: const PlanPostcard(
                  destination: 'Pune',
                  days: 3,
                  activities: 9,
                  stops: [
                    'Raja Dinkar Kelkar Museum',
                    'Sarasbaug',
                    'Vishrambaug Wada',
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      expect(data, isNotNull);
      final bytes = data!.buffer.asUint8List();
      expect(bytes.take(4).toList(), [137, 80, 78, 71]);
      final output = Platform.environment['TRAV_POSTCARD_PREVIEW'];
      if (output != null) await File(output).writeAsBytes(bytes);
    });
  });
}
