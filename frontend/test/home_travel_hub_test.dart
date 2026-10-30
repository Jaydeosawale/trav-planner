import 'package:go_router/go_router.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/nearby_origin.dart';
import 'package:latlong2/latlong.dart';
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
  testWidgets(
    'A day idea asks for a town or explicit location when none is set',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            myTripsProvider.overrideWith((ref) async => []),
            savedPlacesApiProvider.overrideWithValue(TestApi()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: HomeTravelHub())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coffee & slow mornings'));
      await tester.pumpAndSettle();
      expect(find.text('Where is your day happening?'), findsOneWidget);
      expect(find.text('Enter a town'), findsOneWidget);
      expect(find.text('Use my location'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Day ideas carry the selected town and category without another prompt',
    (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: SingleChildScrollView(child: HomeTravelHub()),
            ),
          ),
          GoRoute(
            path: '/explore',
            builder: (_, state) => Scaffold(body: Text(state.uri.toString())),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            myTripsProvider.overrideWith((ref) async => []),
            savedPlacesApiProvider.overrideWithValue(TestApi()),
            chosenPlaceAreaProvider.overrideWith(
              (ref) => const PlaceArea(cityId: 'pune-id', name: 'Pune'),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ideas around Pune'), findsOneWidget);
      await tester.tap(find.text('Coffee & slow mornings'));
      await tester.pumpAndSettle();
      expect(find.text('/explore?city=pune-id&category=cafe'), findsOneWidget);
      expect(find.text('Where is your day happening?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('Shared GPS stays in memory and clears on account change', () {
    final container = ProviderContainer(
      overrides: [authProvider.overrideWith(TestAuth.new)],
    );
    addTearDown(container.dispose);
    container.read(nearbyOriginProvider.notifier).state = const LatLng(
      18.52,
      73.85,
    );
    expect(container.read(nearbyOriginProvider), isNotNull);
    (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
    expect(container.read(nearbyOriginProvider), isNull);
  });
}
