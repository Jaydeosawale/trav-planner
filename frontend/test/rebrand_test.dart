import 'package:trav_planner/features/places/data/place_catalogue.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/home/presentation/pages/home_page.dart';
import 'package:trav_planner/features/home/presentation/providers/home_provider.dart';
import 'package:trav_planner/features/auth/presentation/pages/login_page.dart';
import 'package:trav_planner/features/ai/presentation/pages/ai_search_page.dart';
import 'package:trav_planner/features/explore/presentation/pages/explore_page.dart';
import 'package:trav_planner/features/explore/presentation/providers/explore_provider.dart';
import 'package:trav_planner/features/explore/data/models/explore_country.dart';
import 'package:trav_planner/features/explore/data/models/explore_city.dart';
import 'package:trav_planner/features/trips/presentation/pages/my_trips_page.dart';
import 'package:trav_planner/shared/navigation/mobile_bottom_nav.dart';
import 'package:trav_planner/shared/navigation/desktop_top_nav.dart';

void main() {
  final boundary = GlobalKey();
  Future<void> setup(WidgetTester tester, Size size, Widget page) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      for (final family in ['Manrope', 'DM Sans', 'Inter']) {
        final loader = FontLoader(family);
        for (final weight in [400, 500, 600, 700, 800]) {
          loader.addFont(
            rootBundle.load(
              'assets/fonts/${family == 'DM Sans' ? 'DMSans' : family}-$weight.ttf',
            ),
          );
        }
        await loader.load();
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placeCatalogueProvider.overrideWith(
            (ref, q) async => const PlaceResults(items: [], total: 0, pages: 0),
          ),
          bannersProvider.overrideWith((ref) async => []),
          destinationsProvider.overrideWith((ref) async => []),
          exploreCountriesProvider.overrideWith(
            (ref) async => [
              ExploreCountry.fromJson({
                'id': 'india',
                'name': 'India',
                'iso2': 'IN',
              }),
            ],
          ),
          exploreCitiesProvider.overrideWith(
            (ref, request) async => const ExploreCitySearchResult(
              items: [],
              total: 0,
              page: 1,
              size: 20,
              pages: 0,
            ),
          ),
          myTripsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(key: boundary, child: page),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final place in ['bali', 'goa', 'paris', 'switzerland']) {
        await precacheImage(
          AssetImage('assets/images/destinations/${place}_1.jpg'),
          boundary.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> capture(String name) async {
    const output = String.fromEnvironment('TRAV_SCREENSHOT_DIR');
    if (output.isEmpty) return;
    final render =
        boundary.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await render.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  }

  for (final width in [320.0, 360.0, 768.0, 1280.0]) {
    testWidgets('Home fits $width and uses viewport navigation', (
      tester,
    ) async {
      await setup(
        tester,
        Size(width, width == 1280 ? 1000 : 1200),
        const HomePage(),
      );
      expect(find.text('Somewhere worth going.'), findsOneWidget);
      expect(find.text('Choose area'), findsNothing);
      expect(tester.takeException(), isNull);
      if (width == 360) expect(find.byType(MobileBottomNav), findsOneWidget);
      if (width == 768) expect(find.byType(NavigationRail), findsOneWidget);
      if (width == 1280) expect(find.byType(DesktopTopNav), findsOneWidget);
      await tester.runAsync(() => capture('trav-home-${width.toInt()}'));
      if (width == 360) {
        expect(find.text('Profile'), findsNothing);
        await tester.tap(find.bySemanticsLabel('Sign in'));
        await tester.pumpAndSettle();
        expect(find.byType(LoginPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('Sign-in and AI layouts fit a narrow phone', (tester) async {
    await setup(tester, const Size(360, 1000), const LoginPage());
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => capture('trav-login'));
    await setup(tester, const Size(360, 1000), const AISearchPage());
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => capture('trav-ai-planner'));
  });
  testWidgets('Explore inspiration opens the destination search', (
    tester,
  ) async {
    await setup(tester, const Size(360, 1100), const ExplorePage());
    expect(tester.takeException(), isNull);
    await tester.runAsync(() => capture('trav-explore'));
    await tester.tap(find.text('Panaji').first);
    await tester.pumpAndSettle();
    expect(find.text('Search results for "Panaji"'), findsOneWidget);
    expect(find.text('No cities found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Trip empty state opens the AI planner', (tester) async {
    await setup(tester, const Size(360, 1000), const MyTripsPage());
    await tester.runAsync(() => capture('trav-my-trips'));
    await tester.tap(find.text('Explore ideas with AI'));
    await tester.pumpAndSettle();
    expect(find.byType(AISearchPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
