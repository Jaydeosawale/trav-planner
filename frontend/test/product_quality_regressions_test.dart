import 'place_browsing_product_test.dart' show fontsAndPhoto, captureScreen;
import 'package:trav_planner/features/trips/presentation/pages/trip_details_page.dart';
import 'package:trav_planner/features/profile/presentation/pages/profile_page.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'package:trav_planner/features/ai/data/models/ai_response_model.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/trips/data/trips_api.dart';
import 'package:trav_planner/features/trips/presentation/pages/my_trips_page.dart';
import 'package:trav_planner/features/trips/presentation/pages/trip_editor_page.dart';
import 'package:trav_planner/features/trips/presentation/pages/trip_budget_page.dart';
import 'package:trav_planner/features/explore/presentation/pages/nearby_places_page.dart';
import 'saved_places_test.dart' show TestAuth;

class QualityTrips extends TripsApi {
  final saves = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> list(int page) async {
    if (fail) throw Exception('offline');
    return {'items': <Map<String, dynamic>>[], 'pages': 1};
  }

  @override
  Future<List<Map<String, dynamic>>> cities(String query) async => [
    {
      'id': query.toLowerCase(),
      'name': query,
      'currency': query == 'Paris' ? 'EUR' : 'INR',
    },
  ];
  @override
  Future<Map<String, dynamic>> save(
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    saves.add(Map.of(payload));
    if (fail) throw Exception('offline');
    return {'id': id ?? 'new', ...payload};
  }
}

class AnswerAI extends AIApi {
  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
    Map<String, double>? location,
  }) async => const AIResponseModel(
    success: true,
    content: 'Paris is the capital of France.',
    agent: 'test',
    data: {},
    metadata: {'planning_stage': 'answer'},
  );
}

class DelayedTrips extends TripsApi {
  final oldAccount = Completer<Map<String, dynamic>>();
  int calls = 0;
  @override
  Future<Map<String, dynamic>> list(int page) => ++calls == 1
      ? oldAccount.future
      : Future.value({'items': <Map<String, dynamic>>[], 'pages': 2});
}

class DelayedAI extends AIApi {
  final response = Completer<AIResponseModel>();
  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
    Map<String, double>? location,
  }) => response.future;
}

void main() {
  for (final width in [320.0, 1280.0]) {
    testWidgets('Trip utilities and profile fit $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await fontsAndPhoto(tester);
      final trip = <String, dynamic>{
        'id': 'preview',
        'title': 'A weekend in Paris',
        'start_date': '2026-11-14',
        'end_date': '2026-11-16',
        'travelers': 2,
        'status': 'planned',
        'budget_amount': '500',
        'budget_currency': 'EUR',
        'notes':
            'A draft idea for a relaxed weekend. Check details before travel.',
      };
      for (final entry in <String, Widget>{
        'budget': TripBudgetPage(trip: trip),
        'trip-details': const TripDetailsPage(id: 'preview'),
        'profile': const ProfilePage(),
      }.entries) {
        await tester.pumpWidget(
          ProviderScope(
            key: ValueKey(entry.key),
            overrides: [
              authProvider.overrideWith(TestAuth.new),
              tripDetailsProvider('preview').overrideWith((ref) async => trip),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              home: RepaintBoundary(child: entry.value),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: entry.key);
        await captureScreen(tester, 'trav-${entry.key}-${width.toInt()}');
      }
    });
  }

  test('Trip page counts do not leak between accounts', () {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(TestAuth.new)],
    );
    addTearDown(container.dispose);
    container.read(tripPagesProvider.notifier).state = 8;
    (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
    expect(container.read(tripPagesProvider), 1);
  });

  testWidgets(
    'Empty trips hide pagination and refresh failures stay in the list',
    (tester) async {
      final api = QualityTrips();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            tripsApiProvider.overrideWithValue(api),
          ],
          child: MaterialApp(theme: AppTheme.light, home: const MyTripsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Previous'), findsNothing);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Page 1'), findsNothing);
      api.fail = true;
      final refresh = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pumpAndSettle();
      await refresh;
      expect(find.text('We couldn’t load your trips.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Changing destination text clears the selected city and verified currency follows selection',
    (tester) async {
      final api = QualityTrips();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            tripsApiProvider.overrideWithValue(api),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const TripEditorPage(),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('trip-title')),
        'Weekend',
      );
      await tester.enterText(
        find.byKey(const ValueKey('trip-city-search')),
        'Pune',
      );
      await tester.tap(find.byTooltip('Search cities'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Pune'));
      await tester.enterText(
        find.byKey(const ValueKey('trip-city-search')),
        'Paris',
      );
      await tester.ensureVisible(find.text('Save trip'));
      await tester.tap(find.text('Save trip'));
      await tester.pumpAndSettle();
      expect(
        find.text('Search and select a city for this trip.'),
        findsOneWidget,
      );
      expect(api.saves, isEmpty);
      await tester.ensureVisible(find.byTooltip('Search cities'));
      await tester.tap(find.byTooltip('Search cities'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Paris'));
      final currency = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Currency code'),
      );
      expect(currency.controller!.text, 'EUR');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Known planner facts prefill the review form without inventing dates',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TripEditorPage(
              draftTitle: 'Paris escape',
              initialBrief: {
                'destination': 'Paris',
                'travelers': 2,
                'dates': '2027-02-03 to 2027-02-05',
                'budget': 'EUR 600',
              },
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('trip-title')))
            .controller!
            .text,
        'Paris escape',
      );
      expect(find.text('Paris'), findsOneWidget);
      expect(find.text('Start: 2027-02-03'), findsOneWidget);
      expect(find.text('End: 2027-02-05'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'Currency code'),
            )
            .controller!
            .text,
        'EUR',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Budget rejects invalid amounts and preserves a failed save before retry',
    (tester) async {
      final api = QualityTrips()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            tripsApiProvider.overrideWithValue(api),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TripBudgetPage(
                        trip: {
                          'id': 'one',
                          'title': 'Paris',
                          'travelers': 2,
                          'budget_currency': 'EUR',
                        },
                      ),
                    ),
                  ),
                  child: const Text('Open budget'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open budget'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('budget-amount')), '-1');
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();
      expect(api.saves, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('budget-amount')),
        '600',
      );
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Couldn’t save the budget. Your changes are kept; try again.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('budget-amount')))
            .controller!
            .text,
        '600',
      );
      api.fail = false;
      await tester.tap(find.text('Save budget'));
      await tester.pumpAndSettle();
      expect(api.saves.last, {
        'budget_amount': '600',
        'budget_currency': 'EUR',
      });
      expect(find.text('Open budget'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'An old nearby request cannot show results after the account changes',
    (tester) async {
      final pending = Completer<Response>();
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) async {
              final r = await pending.future;
              h.resolve(Response(requestOptions: o, data: r.data));
            },
          ),
        );
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith(TestAuth.new)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: NearbyPlacesPage(
              client: dio,
              initialOrigin: const LatLng(18.52, 73.85),
            ),
          ),
        ),
      );
      await tester.pump();
      (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
      await tester.pump();
      pending.complete(
        Response(
          requestOptions: RequestOptions(),
          data: {
            'items': [
              {
                'id': 'private-context',
                'name': 'Old account place',
                'place_type': 'cafe',
              },
            ],
            'message': '',
            'distance_note': '',
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old account place'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'A delayed old account response cannot overwrite the new pagination',
    () async {
      final api = DelayedTrips();
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(TestAuth.new),
          tripsApiProvider.overrideWithValue(api),
        ],
      );
      addTearDown(container.dispose);
      container.listen(myTripsProvider, (_, next) {});
      await Future<void>.delayed(Duration.zero);
      (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
      await container.read(myTripsProvider.future);
      expect(container.read(tripPagesProvider), 2);
      api.oldAccount.complete({'items': <Map<String, dynamic>>[], 'pages': 9});
      await Future<void>.delayed(Duration.zero);
      expect(container.read(tripPagesProvider), 2);
    },
  );
  testWidgets(
    'A factual AI answer does not offer to save a nonexistent itinerary',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: AISearchPage(api: AnswerAI())),
        ),
      );
      await tester.enterText(find.byType(TextField), 'What is Paris?');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(find.text('Review & save to My Trips'), findsNothing);
      expect(find.text('Less walking'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Guest profile offers sign-in and no logout action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfilePage())),
    );
    expect(find.text('Logout'), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Budget editing remains usable on a narrow phone with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(TestAuth.new)],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const TripBudgetPage(
              trip: {
                'id': 'one',
                'title': 'A longer trip title for a family holiday',
                'travelers': 2,
                'budget_currency': 'EUR',
              },
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Save budget'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'City search carries the verified country currency into trip creation',
    () async {
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              h.resolve(
                Response(
                  requestOptions: o,
                  data: o.path == '/countries/active'
                      ? {
                          'data': [
                            {'id': 'fr', 'name': 'France', 'currency_code': 'EUR'},
                          ],
                        }
                      : {
                          'data': {
                            'items': [
                              {
                                'id': 'paris',
                                'name': 'Paris',
                                'country_id': 'fr',
                              },
                            ],
                          },
                        },
                ),
              );
            },
          ),
        );
      final cities = await TripsApi(client: dio).cities('Paris');
      expect(cities.single['country'], 'France');
      expect(cities.single['currency'], 'EUR');
    },
  );
  testWidgets(
    'Changing accounts clears the chat and rejects a late private AI reply',
    (tester) async {
      final api = DelayedAI();
      final container = ProviderContainer(
        overrides: [authProvider.overrideWith(TestAuth.new)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: AISearchPage(api: api)),
        ),
      );
      await tester.enterText(find.byType(TextField), 'My private Paris plan');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
      await tester.pump();
      api.response.complete(
        const AIResponseModel(
          success: true,
          content: 'Old private itinerary',
          agent: 'test',
          data: {},
          metadata: {'planning_stage': 'plan'},
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My private Paris plan'), findsNothing);
      expect(find.text('Old private itinerary'), findsNothing);
      expect(find.text('Where shall we go?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
