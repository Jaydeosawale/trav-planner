import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/trips/data/trips_api.dart';
import 'package:trav_planner/features/trips/presentation/pages/my_trips_page.dart';
import 'package:trav_planner/features/trips/presentation/pages/trip_editor_page.dart';
import 'saved_places_test.dart' show TestAuth;

class MemoryTrips extends TripsApi {
  final items = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<Map<String, dynamic>> list(int page) async => {
    'items': items,
    'pages': 1,
  };
  @override
  Future<Map<String, dynamic>> get(String id) async =>
      Map.of(items.firstWhere((trip) => trip['id'] == id));
  @override
  Future<List<Map<String, dynamic>>> cities(String query) async => [
    {'id': 'pune', 'name': 'Pune'},
  ];
  @override
  Future<Map<String, dynamic>> save(
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    if (fail) throw Exception('offline');
    final trip = <String, dynamic>{
      'id': id ?? 'trip',
      'status': 'planned',
      ...payload,
    };
    items.removeWhere((item) => item['id'] == trip['id']);
    items.add(trip);
    return trip;
  }

  @override
  Future<void> remove(String id) async {
    items.removeWhere((trip) => trip['id'] == id);
  }
}

void main() {
  testWidgets('Create city trip, reopen, edit, and remove on a narrow screen', (
    tester,
  ) async {
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
        child: MaterialApp(theme: AppTheme.light, home: const MyTripsPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a trip'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('trip-title')),
      'Pune escape',
    );
    await tester.enterText(
      find.byKey(const ValueKey('trip-city-search')),
      'Pune',
    );
    await tester.tap(find.byTooltip('Search cities'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pune'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start: Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('End: Choose date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save trip'));
    await tester.tap(find.text('Save trip'));
    await tester.pumpAndSettle();
    expect(api.items.single['city_id'], 'pune');
    expect(find.text('Pune escape'), findsOneWidget);
    await tester.tap(find.text('Pune escape'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit trip'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('trip-title')),
      'Revised escape',
    );
    await tester.ensureVisible(find.text('Save trip'));
    await tester.tap(find.text('Save trip'));
    await tester.pumpAndSettle();
    expect(api.items.single['title'], 'Revised escape');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Remove trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(api.items, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
