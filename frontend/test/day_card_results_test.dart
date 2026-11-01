import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/core/theme/app_theme.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/place_catalogue.dart';
import 'package:trav_planner/features/places/presentation/browse_places_page.dart';
import 'package:trav_planner/features/saved/presentation/saved_places_provider.dart';
import 'saved_places_test.dart' show TestAuth, TestApi;

void main() {
  testWidgets(
    'Reused Explore loads a day-card category and restores it without another request',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cafe = Completer<Map<String, dynamic>>();
      final calls = <String>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) async {
              final kind = request.queryParameters['kind'].toString();
              calls.add(kind);
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: kind == 'cafe'
                      ? await cafe.future
                      : {
                          'items': kind == 'park'
                              ? [
                                  {
                                    'id': 'park',
                                    'name': 'Pune garden',
                                    'place_type': 'park',
                                  },
                                ]
                              : [],
                        },
                ),
              );
            },
          ),
        );
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(TestAuth.new),
          savedPlacesApiProvider.overrideWithValue(TestApi()),
          chosenPlaceAreaProvider.overrideWith(
            (ref) => const PlaceArea(cityId: 'pune', name: 'Pune'),
          ),
          placeAreaApiProvider.overrideWithValue(PlaceAreaApi(client: dio)),
          placeCatalogueProvider.overrideWith(
            (ref, query) async =>
                const PlaceResults(items: [], total: 0, pages: 0),
          ),
        ],
      );
      addTearDown(container.dispose);
      Future<void> open(String type) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: BrowsePlacesPage(
                key: const ValueKey('same-explore'),
                initialQuery: PlaceQuery(cityId: 'pune', type: type),
              ),
            ),
          ),
        );
        if (type == 'cafe' && !cafe.isCompleted) {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 50));
        } else {
          await tester.pumpAndSettle();
        }
      }

      await open('all');
      await open('cafe');
      expect(calls, ['local', 'cafe']);
      expect(find.text('No places match yet.'), findsNothing);
      cafe.complete({
        'items': [
          {
            'id': 'cafe',
            'name': 'Pune coffee stop',
            'place_type': 'cafe',
            'visiting_notes': 'Powered by Geoapify',
          },
        ],
      });
      await tester.pumpAndSettle();
      expect(find.text('Pune coffee stop'), findsOneWidget);
      expect(find.text('1 local place loaded'), findsOneWidget);
      expect(find.text('Powered by Geoapify'), findsOneWidget);
      await open('park');
      expect(find.text('Pune garden'), findsOneWidget);
      await open('cafe');
      expect(find.text('Pune coffee stop'), findsOneWidget);
      expect(calls.where((kind) => kind == 'cafe'), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
