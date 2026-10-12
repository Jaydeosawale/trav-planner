import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/itinerary/data/itinerary_api.dart';
import 'package:trav_planner/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:trav_planner/features/trips/presentation/pages/trip_editor_page.dart';
import 'saved_places_test.dart' show TestAuth;
import 'trips_integration_test.dart' show MemoryTrips;

class MemoryItinerary extends ItineraryApi {
  final days = <Map<String, dynamic>>[];
  int counter = 0;
  @override
  Future<List<Map<String, dynamic>>> load(String id) async => List.of(days);
  @override
  Future<void> saveDay(
    String tripId,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    days.add({'id': 'day', 'items': <Map<String, dynamic>>[], ...data});
  }

  @override
  Future<void> saveItem(
    String dayId,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    (days.single['items'] as List).add({'id': 'item-${counter++}', ...data});
  }

  @override
  Future<void> order(String dayId, List<String> ids) async {
    final items = days.single['items'] as List;
    days.single['items'] = ids
        .map((id) => items.firstWhere((item) => item['id'] == id))
        .toList();
  }

  @override
  Future<void> removeDay(String id) async {
    days.clear();
  }
}

void main() {
  testWidgets('Day editor adds activities, changes order, and removes a day', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final trips = MemoryTrips()
      ..items.add({
        'id': 'trip',
        'title': 'Pune escape',
        'start_date': '2026-11-01',
        'end_date': '2026-11-03',
      });
    final api = MemoryItinerary();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(TestAuth.new),
          tripsApiProvider.overrideWithValue(trips),
          itineraryApiProvider.overrideWithValue(api),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ItineraryPage(tripId: 'trip'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Day one');
    await tester.tap(find.text('Save day'));
    await tester.pumpAndSettle();
    for (final title in ['Museum walk', 'Coffee break']) {
      await tester.ensureVisible(find.text('Add activity'));
      await tester.tap(find.text('Add activity'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('activity-title')),
        title,
      );
      await tester.ensureVisible(find.text('Save activity'));
      await tester.tap(find.text('Save activity'));
      await tester.pumpAndSettle();
    }
    expect((api.days.single['items'] as List).length, 2);
    await tester.tap(find.byTooltip('Activity options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move down'));
    await tester.pumpAndSettle();
    expect(api.days.single['items'][0]['title'], 'Coffee break');
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Remove day'));
    await tester.tap(find.text('Remove day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(api.days, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
