import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/home/presentation/widgets/home_travel_hub.dart';
import 'package:trav_planner/features/saved/presentation/saved_places_provider.dart';
import 'package:trav_planner/features/trips/presentation/pages/my_trips_page.dart';
import 'saved_places_test.dart' show TestAuth, TestApi;

void main() {
  testWidgets(
    'Home suggestions use actual saves and trips and clear on account change',
    (tester) async {
      final saved = TestApi();
      saved.records['one'] = [
        const TravelPlace(
          id: 'coffee',
          name: 'A saved café',
          type: 'cafe',
          cityId: 'pune',
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(TestAuth.new),
          savedPlacesApiProvider.overrideWithValue(saved),
          myTripsProvider.overrideWith(
            (ref) async => ref.watch(authProvider).user?.id == 'one'
                ? [
                    {'id': 'trip', 'title': 'Pune weekend', 'city_id': 'pune'},
                  ]
                : [],
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: HomeTravelHub(personalOnly: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pune weekend'), findsOneWidget);
      expect(find.text('More cafés for you'), findsOneWidget);
      expect(find.text('Based on your saved places'), findsOneWidget);
      saved.owner = 'two';
      (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
      await tester.pumpAndSettle();
      expect(find.text('Pune weekend'), findsNothing);
      expect(find.text('More cafés for you'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
