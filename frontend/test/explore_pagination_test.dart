import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/explore/data/models/explore_city.dart';
import 'package:trav_planner/features/explore/presentation/pages/explore_page.dart';
import 'package:trav_planner/features/explore/presentation/providers/explore_provider.dart';

void main() {
  testWidgets('city pages load on demand and reset for a new search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final requests = <ExploreCitySearchRequest>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exploreCountriesProvider.overrideWith((ref) async => []),
          exploreCitiesProvider.overrideWith((ref, request) async {
            requests.add(request);
            return ExploreCitySearchResult(
              items: [
                ExploreCity(
                  id: 'city',
                  countryId: 'country',
                  stateId: 'state',
                  name: 'City page ${request.page}',
                  isActive: true,
                ),
              ],
              total: 21,
              page: request.page,
              size: 20,
              pages: 2,
            );
          }),
        ],
        child: const MaterialApp(home: ExplorePage(initialQuery: 'Paris')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next'));
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(requests.last.page, 2);
    expect(find.text('City page 2'), findsOneWidget);
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Tokyo');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(requests.last.search, 'Tokyo');
    expect(requests.last.page, 1);
    expect(tester.takeException(), isNull);
  });
}
