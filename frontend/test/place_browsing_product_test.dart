import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/explore/data/models/explore_country.dart';
import 'package:trav_planner/features/explore/presentation/providers/explore_provider.dart';
import 'package:trav_planner/features/home/presentation/providers/home_provider.dart';
import 'package:trav_planner/features/home/presentation/pages/home_page.dart';
import 'package:trav_planner/features/home/presentation/widgets/home_places_section.dart';
import 'package:trav_planner/features/places/data/place_catalogue.dart';
import 'package:trav_planner/features/places/presentation/browse_places_page.dart';
import 'package:trav_planner/features/places/presentation/place_details_page.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/features/trips/presentation/pages/my_trips_page.dart';

const previewPhoto = 'https://preview.invalid/paris.jpg';
TravelPlace example([String type = 'attraction', bool photo = true]) =>
    TravelPlace(
      id: 'preview-place',
      name: 'An afternoon in Paris',
      cityId: 'paris',
      cityName: 'Paris · UI preview',
      type: type == 'all' ? 'attraction' : type,
      imageUrl: photo ? previewPhoto : null,
      description: 'A preview of the place browsing interface.',
    );

Future<void> fontsAndPhoto(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final family in ['Inter', 'Manrope', 'DM Sans']) {
      final loader = FontLoader(family);
      for (final w in [400, 500, 600, 700, 800]) {
        loader.addFont(
          rootBundle.load(
            'assets/fonts/${family == 'DM Sans' ? 'DMSans' : family}-$w.ttf',
          ),
        );
      }
      await loader.load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final bytes = await rootBundle.load(
      'assets/images/destinations/paris_1.jpg',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final imageKey = await const ResizeImage(
      NetworkImage(previewPhoto),
      width: 1000,
    ).obtainKey(const ImageConfiguration());
    PaintingBinding.instance.imageCache.putIfAbsent(
      imageKey,
      () => OneFrameImageStreamCompleter(
        Future.value(ImageInfo(image: frame.image)),
      ),
    );
  });
}

Future<void> captureScreen(WidgetTester tester, String name) async {
  const output = String.fromEnvironment('TRAV_SCREENSHOT_DIR');
  if (output.isEmpty) return;
  await tester.runAsync(() async {
    final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
    img.dispose();
  });
}

void main() {
  test('Wikimedia thumbnails use its public CDN without changing the file', () {
    const path = '/wikipedia/commons/thumb/6/6d/Museum.jpg/960px-Museum.jpg';
    expect(
      displayPhotoUrl('https://thumb.wikimedia.org$path?utm_source=test'),
      'https://upload.wikimedia.org$path',
    );
    expect(
      displayPhotoUrl('https://example.com/image.jpg'),
      'https://example.com/image.jpg',
    );
    expect(displayPhotoUrl(null), isNull);
  });

  testWidgets(
    'Home categories, country and photo filter carry into browse and details',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final queries = <PlaceQuery>[];
      await fontsAndPhoto(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            placeCatalogueProvider.overrideWith((ref, q) async {
              queries.add(q);
              return PlaceResults(items: [example(q.type)], total: 1, pages: 1);
            }),
            exploreCountriesProvider.overrideWith(
              (ref) async => [
                const ExploreCountry(
                  id: 'fr',
                  name: 'France',
                  iso2: 'FR',
                  isActive: true,
                ),
              ],
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: HomePlacesSection(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.single.photosOnly, false);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
      await tester.pumpAndSettle();
      expect(queries.last.type, 'restaurant');
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('France').last);
      await tester.pumpAndSettle();
      if (tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value) {
        await tester.tap(find.byType(SwitchListTile));
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show places'));
      await tester.pumpAndSettle();
      expect(queries.last.countryId, 'fr');
      expect(queries.last.photosOnly, false);
      expect(queries.last.type, 'restaurant');
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(find.byType(BrowsePlacesPage), findsOneWidget);
      expect(queries.last.size, 20);
      expect(queries.last.countryId, 'fr');
      await captureScreen(tester, 'trav-discover-places-preview');
      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(
        find.text('Map locations haven’t been added yet.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cards'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('An afternoon in Paris'));
      await tester.tap(find.text('An afternoon in Paris'));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailsPage), findsOneWidget);
      await captureScreen(tester, 'trav-place-details-preview');
      await tester.ensureVisible(find.text('Plan a visit'));
      await tester.tap(find.text('Plan a visit'));
      await tester.pumpAndSettle();
      expect(find.byType(AISearchPage), findsOneWidget);
      expect(find.text('Sign in to plan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty photo selection can include places without inventing photos',
    (tester) async {
      final queries = <PlaceQuery>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exploreCountriesProvider.overrideWith((ref) async => []),
            placeCatalogueProvider.overrideWith((ref, q) async {
              queries.add(q);
              return PlaceResults(
                items: q.photosOnly ? [] : [example('museum', false)],
                total: q.photosOnly ? 0 : 1,
                pages: q.photosOnly ? 0 : 1,
              );
            }),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: HomePlacesSection(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.tap(find.text('Show places'));
      await tester.pumpAndSettle();
      expect(find.text('No photos for this selection yet.'), findsOneWidget);
      await tester.tap(find.text('Include places without photos'));
      await tester.pumpAndSettle();
      expect(queries.last.photosOnly, false);
      expect(find.text('No photo yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact Home with photo feed fits a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await fontsAndPhoto(tester);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bannersProvider.overrideWith((ref) async => []),
          destinationsProvider.overrideWith((ref) async => []),
          placeCatalogueProvider.overrideWith(
            (ref, q) async =>
                PlaceResults(items: [example()], total: 1, pages: 1),
          ),
          myTripsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(key: boundary, child: const HomePage()),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final name in ['bali', 'goa', 'paris', 'switzerland']) {
        await precacheImage(
          AssetImage('assets/images/destinations/${name}_1.jpg'),
          boundary.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    const output = String.fromEnvironment('TRAV_SCREENSHOT_DIR');
    if (output.isNotEmpty)
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final img = await render.toImage(pixelRatio: 2);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$output/trav-home-place-feed-preview.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        img.dispose();
      });
  });
}
