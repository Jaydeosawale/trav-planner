import 'package:trav_planner/features/places/presentation/widgets/place_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/home/presentation/pages/home_page.dart';
import 'package:trav_planner/features/home/presentation/widgets/destination_spotlight.dart';
import 'package:trav_planner/features/home/presentation/providers/home_provider.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/place_catalogue.dart';
import 'package:trav_planner/features/booking/presentation/pages/booking_links_page.dart';
import 'place_browsing_product_test.dart' as preview;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Home keeps area and real place accessible at ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await preview.fontsAndPhoto(tester);
      final queries = <PlaceQuery>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chosenPlaceAreaProvider.overrideWith(
              (ref) => const PlaceArea(
                cityId: 'paris',
                name: 'Paris',
                countryName: 'France',
              ),
            ),
            bannersProvider.overrideWith((ref) async => []),
            destinationsProvider.overrideWith((ref) async => []),
            placeCatalogueProvider.overrideWith((ref, query) async {
              queries.add(query);
              return PlaceResults(
                items: [preview.example()],
                total: 1,
                pages: 1,
              );
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.last.cityId, 'paris');
      expect(find.text('Explore Paris'), findsOneWidget);
      expect(find.text('Choose area'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      if (scale == 1) {
        final banner = tester.getRect(find.byType(DestinationSpotlight));
        final search = tester.getRect(find.byType(TextField));
        expect(banner.height, greaterThanOrEqualTo(260));
        expect(search.top, greaterThan(banner.top));
        expect(search.bottom, lessThan(banner.bottom));
        expect(
          tester.getRect(find.text('Explore Paris')).top,
          greaterThan(banner.bottom),
        );
        final name = tester.getRect(find.byType(PlaceCard).first);
        expect(
          name.top,
          lessThan(720),
          reason: 'The photo feed begins in the first mobile viewport.',
        );
      } else {
        await tester.ensureVisible(find.text('An afternoon in Paris'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets('Home scroll loads another page without opening See all', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await preview.fontsAndPhoto(tester);
    final pages = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bannersProvider.overrideWith((ref) async => []),
          placeCatalogueProvider.overrideWith((ref, query) async {
            pages.add(query.page);
            return PlaceResults(
              items: List.generate(4, (_) => preview.example()),
              total: 8,
              pages: 2,
            );
          }),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -1800),
    );
    await tester.pumpAndSettle();
    expect(pages, contains(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Supplier handoff retains trip reference without promising transfer',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: BookingLinksPage(
            destination: 'Wai',
            startDate: DateTime(2026, 11, 1),
            travelers: 2,
          ),
        ),
      );
      expect(find.text('Wai'), findsOneWidget);
      expect(find.text('2 travelers'), findsOneWidget);
      expect(
        find.textContaining('not transferred automatically'),
        findsOneWidget,
      );
    },
  );
}
