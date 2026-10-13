import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/core/widgets/travel_markdown.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'package:trav_planner/features/ai/data/models/ai_response_model.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/trips/presentation/pages/trip_editor_page.dart';
import 'saved_places_test.dart' show TestAuth;
import 'trips_integration_test.dart' show MemoryTrips;

const draft =
    '# Paris day\n\n**Eiffel Tower** — catalogue place.\n\n| Time | Activity |\n| --- | --- |\n| Morning | Eiffel Tower |\n\nGeneral suggestions are unverified.';

class SuccessfulAI extends AIApi {
  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
  }) async => const AIResponseModel(
    success: true,
    content: draft,
    agent: 'test',
    data: {},
    metadata: {},
  );
}

void main() {
  testWidgets(
    'AI review cancels safely, retains failed draft, saves and reopens once',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = MemoryTrips();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            tripsApiProvider.overrideWithValue(api),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: AISearchPage(api: SuccessfulAI()),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Paris day');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(find.byType(TravelMarkdown), findsOneWidget);
      expect(find.byType(Table), findsOneWidget);
      Future<void> review() async {
        await tester.ensureVisible(find.text('Review & save to My Trips'));
        await tester.tap(find.text('Review & save to My Trips'));
        await tester.pumpAndSettle();
      }

      await review();
      expect(api.items, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(api.items, isEmpty);
      await review();
      final notes = tester
          .widget<TextFormField>(find.byKey(const ValueKey('trip-notes')))
          .controller!
          .text;
      expect(notes, contains(draft));
      await tester.enterText(
        find.byKey(const ValueKey('trip-title')),
        'My reviewed trip',
      );
      await tester.enterText(
        find.byKey(const ValueKey('trip-city-search')),
        'Pune',
      );
      await tester.tap(find.byTooltip('Search cities'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Pune'));
      await tester.pumpAndSettle();
      for (final date in ['Start: Choose date', 'End: Choose date']) {
        await tester.ensureVisible(find.text(date));
        await tester.tap(find.text(date));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
      }
      api.fail = true;
      await tester.ensureVisible(find.text('Save trip'));
      await tester.tap(find.text('Save trip'));
      await tester.pumpAndSettle();
      expect(api.items, isEmpty);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('trip-notes')))
            .controller!
            .text,
        notes,
      );
      api.fail = false;
    await tester.ensureVisible(find.text('Save trip'));
      await tester.tap(find.text('Save trip'));
      await tester.pumpAndSettle();
      expect(api.items.single['notes'], notes);
      await tester.ensureVisible(find.text('Open saved trip'));
      await tester.tap(find.text('Open saved trip'));
      await tester.pumpAndSettle();
      expect(find.text('My reviewed trip'), findsOneWidget);
      expect(find.byType(TravelMarkdown), findsOneWidget);
      expect(api.items.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
