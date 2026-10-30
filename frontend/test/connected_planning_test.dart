import 'package:dio/dio.dart';
import 'package:trav_planner/features/ai/presentation/pages/structured_plan_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/itinerary/data/itinerary_api.dart';
import 'package:trav_planner/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:trav_planner/features/places/presentation/place_trip_picker.dart';
import 'package:trav_planner/features/trips/data/trips_api.dart';
import 'package:trav_planner/features/trips/presentation/pages/trip_editor_page.dart';
import 'saved_places_test.dart' show TestAuth;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'package:trav_planner/features/ai/data/models/ai_response_model.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/features/ai/presentation/pages/planning_brief_values.dart';

class RetryPlanner extends AIApi {
  final messages = <String>[];
  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
    Map<String, double>? location,
  }) async {
    messages.add(message);
    return AIResponseModel(
      success: messages.length > 1,
      content: messages.length > 1 ? 'Your sourced visit ideas' : 'Unavailable',
      agent: 'test',
      data: {},
      metadata: {},
    );
  }
}

class PlanningTrips extends TripsApi {
  @override
  Future<Map<String, dynamic>> list(int page) async => {
    'items': [
      {
        'id': 'trip',
        'title': 'Pune weekend',
        'start_date': '2026-12-01',
        'end_date': '2026-12-02',
      },
    ],
    'pages': 1,
  };
}

class PlanningDays extends ItineraryApi {
  final items = <Map<String, dynamic>>[];
  int writes = 0;
  @override
  Future<List<Map<String, dynamic>>> load(String tripId) async => [
    {
      'id': 'day',
      'day_number': 1,
      'date': '2026-12-01',
      'title': 'Old town',
      'items': List.of(items),
    },
  ];
  @override
  Future<void> saveItem(
    String dayId,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    writes++;
    items.add({'id': 'item', ...data});
  }
}

void main() {
  test(
    'Exact brief fields transfer and uncertain values remain as context',
    () {
      final known = PlanningBriefValues({
        'dates': '2026-12-01 to 2026-12-04',
        'budget': 'EUR 2,400 total',
        'travelers': 3,
        'origin': 'Pune',
        'food': 'Vegetarian',
        'transport': 'Train',
      });
      expect(known.start, DateTime(2026, 12, 1));
      expect(known.end, DateTime(2026, 12, 4));
      expect(known.currency, 'EUR');
      expect(known.amount, '2400');
      expect(known.travelers, '3');
      expect(known.context, contains('origin: Pune'));
      final uncertain = PlanningBriefValues({
        'dates': 'Sometime in winter',
        'budget': 'about 20k',
      });
      expect(uncertain.start, isNull);
      expect(uncertain.amount, isNull);
      expect(uncertain.context, contains('Sometime in winter'));
      expect(uncertain.context, contains('about 20k'));
      expect(
        PlanningBriefValues({'budget': '2 people INR 20,000 total'}).amount,
        '20000',
      );
      expect(PlanningBriefValues({'budget': 'INR 20k'}).amount, isNull);
      expect(PlanningBriefValues({'dates': '2026-02-31'}).start, isNull);
    },
  );
  testWidgets(
    'Chat collapses intro, anchors keyboard composer and retries original without losing edited draft',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final api = RetryPlanner();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: AISearchPage(api: api)),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Paris parks');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Where will curiosity\ntake you?'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Paris parks',
      );
      await tester.enterText(
        find.byType(TextField),
        'A separate next question',
      );
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(api.messages, ['Paris parks', 'Paris parks']);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'A separate next question',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(
        tester.getBottomRight(find.byType(TextField)).dy,
        lessThanOrEqualTo(564),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Place joins chosen trip day once and preserves sourced ID', (
    tester,
  ) async {
    final days = PlanningDays();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(TestAuth.new),
          tripsApiProvider.overrideWithValue(PlanningTrips()),
          itineraryApiProvider.overrideWithValue(days),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PlaceTripPicker(
              place: TravelPlace(
                id: 'real-place',
                name: 'Old town museum',
                type: 'museum',
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> add() async {
      await tester.tap(find.text('Add to trip'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.textContaining('Pune weekend'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.textContaining('Day 1 · 2026-12-01'));
      await tester.pumpAndSettle();
    }

    await add();
    expect(days.items.single['place_id'], 'real-place');
    expect(days.items.single['sequence'], 1);
    await add();
    expect(days.writes, 1);
    expect(find.text('This place is already in that day.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Daily plan carries exact brief and selected sourced POI into request',
    (tester) async {
      Map<String, dynamic>? request;
      final client = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              request = Map<String, dynamic>.from(options.data);
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: 503,
                    data: {'detail': 'Try later'},
                  ),
                ),
              );
            },
          ),
        );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StructuredPlanPage(
              client: client,
              initialPlace: const TravelPlace(
                id: 'source-place',
                cityId: 'paris',
                cityName: 'Paris',
                name: 'Local museum',
                type: 'museum',
              ),
              session: const {
                'id': 'session',
                'brief': {
                  'destination': 'Paris',
                  'dates': '2026-12-01 to 2026-12-03',
                  'budget': 'EUR 2,400 total',
                  'travelers': 3,
                  'food': 'Vegetarian',
                },
              },
            ),
          ),
        ),
      );
      expect(find.text('Start: 2026-12-01'), findsOneWidget);
      await tester.ensureVisible(find.text('Generate daily plan'));
      await tester.tap(find.text('Generate daily plan'));
      await tester.pumpAndSettle();
      expect(request?['selected_place_ids'], ['source-place']);
      expect(request?['city_id'], 'paris');
      expect(request?['start_date'], '2026-12-01');
      expect(request?['end_date'], '2026-12-03');
      expect(request?['travelers'], 3);
      expect(request?['currency'], 'EUR');
      expect(request?['budget_amount'], 2400);
      expect(request?['preferences'], contains('food: Vegetarian'));
      expect(tester.takeException(), isNull);
    },
  );
}
