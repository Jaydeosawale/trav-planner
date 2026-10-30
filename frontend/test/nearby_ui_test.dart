import 'package:trav_planner/core/theme/app_theme.dart';
import 'place_browsing_product_test.dart' show fontsAndPhoto;
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/explore/presentation/pages/nearby_places_page.dart';
import 'package:trav_planner/features/places/data/current_location.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'travel_flows_test.dart' show NearbyTestAuth;

class NearbyGps extends CurrentLocationService {
  bool fail = false;
  @override
  Future<LatLng> request() async {
    if (fail)
      throw const LocationAccessFailure(
        'Allow location in settings.',
        openSettings: true,
      );
    return const LatLng(18.52, 73.85);
  }
}

Dio nearbyClient(List<RequestOptions> requests) => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) {
        requests.add(o);
        h.resolve(
          Response(
            requestOptions: o,
            data: {
              'items': [
                {
                  'id': 'cafe',
                  'name': 'Garden café',
                  'city_id': 'pune',
                  'place_type': 'cafe',
                  'distance_km': 0.4,
                },
              ],
              'message': 'Stored places',
              'distance_note': 'Straight-line distances',
            },
          ),
        );
      },
    ),
  );

void main() {
  testWidgets(
    'Compact nearby screen puts results first and applies filters without another search',
    (tester) async {
      await fontsAndPhoto(tester);
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <RequestOptions>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(NearbyTestAuth.new),
            chosenPlaceAreaProvider.overrideWith(
              (ref) => const PlaceArea(
                cityId: 'pune',
                name: 'Pune',
                latitude: 18.52,
                longitude: 73.85,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: NearbyPlacesPage(client: nearbyClient(requests)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pune'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text('A little closer to you.'), findsNothing);
      expect(find.text('Search nearby'), findsNothing);
      expect(tester.getTopLeft(find.text('Garden café')).dy, lessThan(500));
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();
      expect(requests.last.data['kind'], 'restaurant');
      await tester.tap(find.text('5 km · Filters'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('10 km'));
      await tester.tap(find.text('Show places'));
      await tester.pumpAndSettle();
      expect(requests.last.data['radius_km'], 10);
      expect(requests.length, 3);
      const output = String.fromEnvironment('TRAV_SCREENSHOT_DIR');
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byType(RepaintBoundary).first,
          );
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File(
            '$output/nearby-results.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Successful GPS hides location entry and clears old settings guidance',
    (tester) async {
      final gps = NearbyGps()..fail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(NearbyTestAuth.new),
            currentLocationServiceProvider.overrideWithValue(gps),
          ],
          child: MaterialApp(home: NearbyPlacesPage(client: nearbyClient([]))),
        ),
      );
      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      gps.fail = false;
      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsNothing);
      expect(find.text('Allow location in settings.'), findsNothing);
      expect(find.text('Saved GPS area'), findsOneWidget);
      expect(find.text('Use my location'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Garden café'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
