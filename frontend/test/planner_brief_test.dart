import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'package:trav_planner/features/ai/data/models/ai_response_model.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';

class MemoryPlanner extends AIApi {
  Map<String, dynamic>? saved;
  String? usedId;
  bool fail = true;
  @override
  Future<Map<String, dynamic>> saveBrief(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    if (fail) throw Exception('offline');
    saved = {'id': 'session-1', 'turns': [], ...data, 'version': 1};
    return Map.of(saved!);
  }

  @override
  Future<Map<String, dynamic>> session(String id) async => Map.of(saved!);
  @override
  Future<List<Map<String, dynamic>>> sessions() async =>
      saved == null ? [] : [saved!];
  @override
  Future<void> forgetSession(String id) async {
    saved = null;
  }

  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
  }) async {
    usedId = sessionId;
    saved!['turns'] = [
      {'role': 'user', 'content': message},
      {'role': 'assistant', 'content': 'Paris with less walking'},
    ];
    return const AIResponseModel(
      success: true,
      content: 'Paris with less walking',
      agent: 'test',
      data: {},
      metadata: {},
    );
  }
}

void main() {
  testWidgets(
    'Brief failure retains draft, chat uses session, reopen and forget',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = MemoryPlanner();
      await tester.pumpWidget(MaterialApp(home: AISearchPage(api: api)));
      await tester.tap(find.byTooltip('Planner options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trip details'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('brief-destination')),
        'Paris',
      );
      await tester.ensureVisible(find.text('Save brief'));
      await tester.tap(find.text('Save brief'));
      await tester.pumpAndSettle();
      expect(api.saved, isNull);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('brief-destination')),
            )
            .controller!
            .text,
        'Paris',
      );
      api.fail = false;
      await tester.ensureVisible(find.text('Save brief'));
      await tester.tap(find.text('Save brief'));
      await tester.pumpAndSettle();
      expect(api.saved!['brief']['destination'], 'Paris');
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Less walking');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(api.usedId, 'session-1');
      await tester.ensureVisible(find.byTooltip('Recent plans'));
      await tester.tap(find.byTooltip('Recent plans'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(SimpleDialogOption, 'My travel ideas'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your AI travel companion'), findsOneWidget);
      await tester.tap(find.byTooltip('Planner options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forget conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep'));
      await tester.pumpAndSettle();
      expect(api.saved, isNotNull);
      await tester.tap(find.byTooltip('Planner options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forget conversation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forget'));
      await tester.pumpAndSettle();
      expect(api.saved, isNull);
      expect(find.text('Edit brief'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
