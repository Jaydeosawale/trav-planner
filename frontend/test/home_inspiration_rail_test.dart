import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/home/presentation/widgets/home_places_section.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/place_catalogue.dart';
import 'place_browsing_product_test.dart' show fontsAndPhoto, captureScreen;
import 'saved_places_test.dart' show TestAuth, TestApi;
import 'package:trav_planner/features/saved/presentation/saved_places_provider.dart';

void main() {
  testWidgets(
    'Home keeps independent previews without loading or crediting Geoapify',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await fontsAndPhoto(tester);
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'items': [
                      {
                        'id': 'one',
                        'name': 'Pune park',
                        'place_type': 'park',
                        'city_id': 'pune',
                      },
                      {
                        'id': 'two',
                        'name': 'Pune coffee',
                        'place_type': 'cafe',
                        'city_id': 'pune',
                        'visiting_notes': 'Powered by Geoapify',
                      },
                    ],
                  },
                ),
              );
            },
          ),
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(TestAuth.new),
            savedPlacesApiProvider.overrideWithValue(TestApi()),
            chosenPlaceAreaProvider.overrideWith(
              (ref) => const PlaceArea(cityId: 'pune', name: 'Pune'),
            ),
            placeAreaApiProvider.overrideWithValue(PlaceAreaApi(client: dio)),
            placeCatalogueProvider.overrideWith(
              (ref, query) async => const PlaceResults(
                items: [
                  TravelPlace(
                    id: 'one',
                    name: 'Pune park',
                    type: 'park',
                    cityId: 'pune',
                  ),
                  TravelPlace(
                    id: 'sourced',
                    name: 'Sourced coffee',
                    type: 'cafe',
                    visitingNotes: 'Powered by Geoapify',
                  ),
                ],
                total: 1,
                pages: 1,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RepaintBoundary(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: HomePlacesSection(curated: true),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rail = find.byKey(const ValueKey('home-inspiration-rail'));
      expect(find.byType(ListView), findsOneWidget);
      expect(
        tester.widget<ListView>(rail).childrenDelegate.estimatedChildCount,
        1,
      );
      expect(find.text('Pune park'), findsOneWidget);
      expect(find.text('Sourced coffee'), findsNothing);
      expect(find.text('Pune coffee'), findsNothing);
      expect(find.text('Powered by Geoapify'), findsNothing);
      await captureScreen(tester, 'trav-pune-inspiration-320');
      expect(tester.takeException(), isNull);
    },
  );
}
