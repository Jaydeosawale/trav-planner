import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/place_catalogue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/explore/data/models/explore_city.dart';
import 'package:trav_planner/features/explore/data/models/explore_country.dart';
import 'package:trav_planner/features/explore/presentation/pages/explore_page.dart';
import 'package:trav_planner/features/explore/presentation/providers/explore_provider.dart';
import 'package:trav_planner/shared/navigation/adaptive_scaffold.dart';

void main() {
  const india = ExploreCountry(
    id: 'india',
    name: 'India',
    iso2: 'IN',
    isActive: true,
  );
  Future<void> setup(
    WidgetTester tester,
    Widget page,
    List<ExploreCitySearchRequest> calls,
  ) async {
    tester.view.physicalSize = const Size(360, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          areaSearchProvider.overrideWith(
            (ref, request) async => const PlaceAreaResults([]),
          ),
          placeCatalogueProvider.overrideWith(
            (ref, query) async =>
                const PlaceResults(items: [], total: 0, pages: 0),
          ),
          exploreCountriesProvider.overrideWith((ref) async => [india]),
          exploreCitiesProvider.overrideWith((ref, request) async {
            calls.add(request);
            return ExploreCitySearchResult(
              items: List.generate(
                20,
                (i) => ExploreCity(
                  id: '${request.countryId}-${request.page}-$i',
                  countryId: 'india',
                  stateId: 'state',
                  name: 'Page ${request.page} city $i',
                  isActive: true,
                ),
              ),
              total: 40,
              page: request.page,
              size: 20,
              pages: 2,
            );
          }),
        ],
        child: MaterialApp(home: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'browse opens without typing, scroll appends and country resets pages',
    (tester) async {
      final calls = <ExploreCitySearchRequest>[];
      await setup(tester, const ExplorePage(), calls);
      expect(calls.length, 1);
      expect(calls.single.search, isNull);
      expect(find.text('Page 1 city 0'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('explore-scroll')),
        const Offset(0, -5000),
      );
      await tester.pumpAndSettle();
      expect(calls.last.page, 2);
      expect(find.text('Page 1 city 0'), findsOneWidget);
      expect(find.text('Page 2 city 0'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'India'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'India'));
      await tester.pumpAndSettle();
      expect(calls.last.countryId, 'india');
      expect(calls.last.page, 1);
      expect(calls.last.search, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('switching tabs preserves home entry and Explore search', (
    tester,
  ) async {
    final calls = <ExploreCitySearchRequest>[];
    await setup(tester, const AdaptiveScaffold(body: TextField()), calls);
    await tester.enterText(find.byType(TextField), 'Home note');
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tokyo');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Home note'), findsOneWidget);
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    expect(find.text('Tokyo'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('country search offers a direct browse action', (tester) async {
    final calls = <ExploreCitySearchRequest>[];
    await setup(tester, const ExplorePage(initialQuery: 'India'), calls);
    await tester.ensureVisible(find.text('Browse India'));
    await tester.tap(find.text('Browse India'));
    await tester.pumpAndSettle();
    expect(calls.last.countryId, 'india');
    expect(calls.last.search, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('country Cities action returns to its filtered city list', (
    tester,
  ) async {
    final calls = <ExploreCitySearchRequest>[];
    await setup(tester, const ExplorePage(), calls);
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Countries'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Countries'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('India').last);
    await tester.tap(find.text('India').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Cities'));
    await tester.tap(find.text('Cities'));
    await tester.pumpAndSettle();
    expect(calls.last.countryId, 'india');
    expect(calls.last.page, 1);
  });
}
