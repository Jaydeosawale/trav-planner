import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/app/router/app_router.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/home/presentation/providers/home_provider.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/place_catalogue.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'saved_places_test.dart' show TestAuth, TestApi;
import 'package:trav_planner/features/saved/presentation/saved_places_provider.dart';
import 'package:trav_planner/features/trips/presentation/pages/my_trips_page.dart';

void main() {
  testWidgets(
    'Routed tabs keep the search, and a published place opens by URL',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = createAppRouter(
        initialLocation: '/explore?search=Mahabaleshwar&category=cafe',
      );
      addTearDown(router.dispose);
      final requests = <PlaceQuery>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            savedPlacesApiProvider.overrideWithValue(TestApi()),
            myTripsProvider.overrideWith((ref) async => []),
            bannersProvider.overrideWith((ref) async => []),
            destinationsProvider.overrideWith((ref) async => []),
            areaSearchProvider.overrideWith(
              (ref, q) async => const PlaceAreaResults([]),
            ),
            placeCatalogueProvider.overrideWith((ref, q) async {
              requests.add(q);
              return const PlaceResults(items: [], total: 0, pages: 0);
            }),
            placeLinkProvider.overrideWith(
              (ref, id) async =>
                  TravelPlace(id: id, name: 'Sourced museum', type: 'museum'),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests.last.search, 'Mahabaleshwar');
      expect(requests.last.type, 'cafe');
      await tester.enterText(find.byType(TextField), 'Pune');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters['search'],
        'Pune',
      );
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.queryParameters['search'],
        'Pune',
      );
      expect(find.widgetWithText(TextField, 'Pune'), findsOneWidget);
      router.push('/places/museum');
      await tester.pumpAndSettle();
      expect(find.text('Sourced museum'), findsOneWidget);
      expect(
        router.routeInformationParser
            .restoreRouteInformation(
              router.routerDelegate.currentConfiguration,
            )!
            .uri
            .path,
        '/places/museum',
      );
      expect(find.text('Add to trip'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Pune'), findsOneWidget);
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(find.text('Choose area'), findsNothing);
      expect(find.text('Profile'), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/explore');
      expect(tester.widget<TextField>(find.byType(TextField)).autofocus, true);
      expect(tester.takeException(), isNull);
    },
  );
  test('Explore URL keeps real filters and rejects unsupported categories', () {
    final q = placeQueryFromUri(
      Uri.parse(
        '/explore?city=town&country=fr&category=museum&photos=true&search=art',
      ),
    );
    expect(q.cityId, 'town');
    expect(q.countryId, 'fr');
    expect(q.photosOnly, true);
    expect(q.type, 'museum');
    expect(
      placeQueryFromUri(Uri.parse('/explore?category=invalid')).type,
      'all',
    );
  });
}
