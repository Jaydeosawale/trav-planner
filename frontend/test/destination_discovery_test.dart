import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/destinations/data/places_provider.dart';
import 'package:trav_planner/features/destinations/presentation/destination_details_page.dart';

void main() {
  test('only recognized Wikidata IDs produce a location source link', () {
    final base = {
      'id': 'tower',
      'name': 'Eiffel Tower',
      'provider': 'wikidata',
    };
    expect(
      TravelPlace.fromJson({
        ...base,
        'external_place_id': 'Q243',
      }).source.toString(),
      'https://www.wikidata.org/wiki/Q243',
    );
    expect(
      TravelPlace.fromJson({
        ...base,
        'external_place_id': 'https://example.com',
      }).source,
      isNull,
    );
  });
  test(
    'coordinates accept decimal strings and reject missing, invalid, nonfinite values',
    () {
      expect(validCoordinates('18.519', '73.855')?.latitude, 18.519);
      for (final values in [
        [91, 0],
        [0, -181],
        [null, 73],
        ['NaN', 0],
        [0, 'Infinity'],
        ['bad', 0],
      ]) {
        expect(validCoordinates(values[0], values[1]), isNull);
      }
      expect(validCoordinates(0, 0), isNotNull);
    },
  );

  Future<void> show(WidgetTester tester, List<TravelPlace> places) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityPlacesProvider('pune').overrideWith((ref) async => places),
        ],
        child: const MaterialApp(
          home: DestinationDetailsPage(cityId: 'pune', name: 'Pune'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty destination does not invent attractions or coordinates', (
    tester,
  ) async {
    await show(tester, []);
    expect(
      find.text(
        'Places for this destination are being added. Check back soon.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.text('Map locations haven’t been added yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'place without coordinates remains readable with no directions button',
    (tester) async {
      await show(tester, const [
        TravelPlace(
          id: 'fort',
          name: 'Fort',
          type: 'heritage',
          description: 'Historic fort',
        ),
      ]);
      await tester.tap(find.text('Fort'));
      await tester.pumpAndSettle();
      expect(find.text('Historic fort'), findsOneWidget);
      expect(find.text('Map location is being added.'), findsOneWidget);
      expect(find.text('Get directions'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('category chips filter destination cards', (tester) async {
    await show(tester, const [
      TravelPlace(id: 'fort', name: 'Fort', type: 'heritage'),
      TravelPlace(id: 'park', name: 'Park', type: 'nature'),
    ]);
    await tester.tap(find.widgetWithText(ChoiceChip, 'nature'));
    await tester.pumpAndSettle();
    expect(find.text('Park'), findsOneWidget);
    expect(find.text('Fort'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
