import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trav_planner/features/ai/data/datasources/ai_api.dart';
import 'package:trav_planner/features/ai/data/models/ai_response_model.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/features/places/data/current_location.dart';
import 'package:trav_planner/features/places/data/nearby_origin.dart';

class FakeLocation extends CurrentLocationService {
  int calls = 0;
  bool denied = false;
  @override
  Future<LatLng> request() async {
    calls++;
    if (denied)
      throw const LocationAccessFailure(
        'Location wasn’t shared. You can enter a town instead.',
      );
    return const LatLng(18.52, 73.85);
  }
}

class LocationAI extends AIApi {
  final locations = <Map<String, double>?>[];
  @override
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
    Map<String, double>? location,
  }) async {
    locations.add(location);
    return const AIResponseModel(
      success: true,
      content: 'Here are some nearby ideas.',
      agent: 'test',
      data: {},
      metadata: {},
    );
  }
}

void main() {
  testWidgets(
    'Location needs explicit consent, is sent only when shared, and can be removed',
    (tester) async {
      final gps = FakeLocation();
      final api = LocationAI();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentLocationServiceProvider.overrideWithValue(gps)],
          child: MaterialApp(home: AISearchPage(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(gps.calls, 0);
      await tester.tap(find.byTooltip('Use my location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(gps.calls, 0);
      await tester.tap(find.byTooltip('Use my location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use current location'));
      await tester.pumpAndSettle();
      expect(gps.calls, 1);
      expect(find.byTooltip('Location shared · refresh'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Plan a day near me');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(api.locations.single, {'latitude': 18.52, 'longitude': 73.85});
      await tester.tap(find.byTooltip('Planner options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove shared location'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Plan Paris instead');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(api.locations.last, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Denied location keeps manual chat usable without sharing coordinates',
    (tester) async {
      final gps = FakeLocation()..denied = true;
      final container = ProviderContainer(
        overrides: [currentLocationServiceProvider.overrideWithValue(gps)],
      );
      addTearDown(container.dispose);
      final api = LocationAI();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: AISearchPage(api: api)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Pune for 2 days');
      await tester.tap(find.byTooltip('Use my location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use current location'));
      await tester.pumpAndSettle();
      expect(container.read(nearbyOriginProvider), isNull);
      expect(container.read(aiLocationEnabledProvider), isFalse);
      expect(find.text('Pune for 2 days'), findsOneWidget);
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(api.locations.single, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
