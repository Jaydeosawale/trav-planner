import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'saved_places_test.dart' show TestAuth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trav_planner/features/places/presentation/browse_places_page.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/place_catalogue.dart';

class LocationAdapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  bool failIndex = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    Object data;
    switch (options.path) {
      case '/countries/active':
        data = {
          'data': [
            {'id': 'india', 'name': 'India', 'iso2': 'IN'},
          ],
        };
      case '/states/country/india':
        data = {
          'data': [
            {'id': 'mh', 'name': 'Maharashtra'},
          ],
        };
      case '/cities/search':
        data = {
          'data': {
            'items': [
              {
                'id': 'pune',
                'name': 'Pune',
                'country_id': 'india',
                'state_id': 'mh',
                'latitude': 18.52,
                'longitude': 73.85,
              },
            ],
          },
        };
      case '/discovery/locations':
        if (failIndex) {
          return ResponseBody.fromString(
            '{}',
            503,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }
        data = {
          'items': [
            {
              'id': '1264491',
              'name': 'Mahabaleshwar',
              'country': 'IN',
              'country_name': 'India',
              'region_name': 'Maharashtra',
              'latitude': 17.9,
              'longitude': 73.65,
            },
            {
              'id': '1259229',
              'name': 'Pune',
              'country': 'IN',
              'country_name': 'India',
              'region_name': 'Maharashtra',
              'latitude': 18.52,
              'longitude': 73.85,
            },
          ],
        };
      default:
        throw StateError('Unexpected call ${options.path}');
    }
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'area search merges settlement matches even when catalogue cities exist; deduplicates and labels regions',
    () async {
      final adapter = LocationAdapter();
      final api = PlaceAreaApi(client: Dio()..httpClientAdapter = adapter);
      final result = await api.search('Pune', countryId: 'india');
      expect(
        result.items.map((a) => a.name),
        containsAll(['Pune', 'Mahabaleshwar']),
      );
      expect(result.items.where((a) => a.name == 'Pune'), hasLength(1));
      expect(result.items.singleWhere((a) => a.name == 'Pune').cityId, 'pune');
      expect(
        result.items.every((a) => a.subtitle == 'Maharashtra · India'),
        isTrue,
      );
      expect(
        adapter.calls
            .singleWhere((c) => c.path == '/discovery/locations')
            .queryParameters['country'],
        'IN',
      );
      expect(
        adapter.calls.any((c) => c.path.contains('/discovery/cities/')),
        isFalse,
      );
      expect(adapter.calls.any((c) => c.method == 'POST'), isFalse);
    },
  );
  test(
    'one location source failing retains other matches with a clear notice',
    () async {
      final adapter = LocationAdapter()..failIndex = true;
      final result = await PlaceAreaApi(
        client: Dio()..httpClientAdapter = adapter,
      ).search('Pune');
      expect(result.items.single.name, 'Pune');
      expect(result.notice, isNotNull);
    },
  );
  testWidgets(
    'empty catalogue immediately offers locations and selection keeps category in area results',
    (tester) async {
      final requests = <PlaceQuery>[];
      final container = ProviderContainer(
        overrides: [
          areaSearchProvider.overrideWith(
            (ref, request) async => const PlaceAreaResults([
              PlaceArea(
                cityId: 'mahabaleshwar',
                name: 'Mahabaleshwar',
                regionName: 'Maharashtra',
                countryName: 'India',
                countryId: 'india',
              ),
            ]),
          ),
          placeCatalogueProvider.overrideWith((ref, request) async {
            requests.add(request);
            return PlaceResults(
              items: request.cityId == null
                  ? []
                  : [
                      const TravelPlace(
                        id: 'local-place',
                        name: 'Local café',
                        type: 'cafe',
                        cityId: 'mahabaleshwar',
                      ),
                    ],
              total: request.cityId == null ? 0 : 1,
              pages: 1,
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: BrowsePlacesPage(
              initialQuery: PlaceQuery(search: 'Mahabaleshwar', type: 'cafe'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Destinations'), findsOneWidget);
      expect(find.text('Maharashtra · India'), findsOneWidget);
      final candidate = find.widgetWithText(ListTile, 'Mahabaleshwar');
      await tester.ensureVisible(candidate);
      await tester.tap(candidate);
      await tester.pumpAndSettle();
      expect(container.read(chosenPlaceAreaProvider)?.cityId, 'mahabaleshwar');
      expect(
        requests.any(
          (q) =>
              q.cityId == 'mahabaleshwar' &&
              q.type == 'cafe' &&
              q.search.isEmpty,
        ),
        isTrue,
      );
      await tester.enterText(find.byType(TextField), 'Paris');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(requests.last.search, 'Paris');
      expect(requests.last.cityId, isNull);
      expect(requests.last.countryId, isNull);

      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('signed-in town opens local sources without another button', (
    tester,
  ) async {
    final calls = <RequestOptions>[];
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          calls.add(request);
          handler.resolve(
            Response(requestOptions: request, data: {'items': []}),
          );
        },
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(TestAuth.new),
          chosenPlaceAreaProvider.overrideWith(
            (ref) => const PlaceArea(cityId: 'wai', name: 'Wai'),
          ),
          placeAreaApiProvider.overrideWithValue(PlaceAreaApi(client: dio)),
          placeCatalogueProvider.overrideWith(
            (ref, q) async => const PlaceResults(items: [], total: 0, pages: 0),
          ),
        ],
        child: const MaterialApp(
          home: BrowsePlacesPage(initialQuery: PlaceQuery(cityId: 'wai')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(calls.single.path, '/discovery/cities/wai');
    expect(calls.single.queryParameters['kind'], 'local');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.pumpAndSettle();
    expect(calls, hasLength(2));
    expect(calls.last.queryParameters['kind'], 'restaurant');
    await tester.tap(find.text('Photos only'));
    await tester.pumpAndSettle();
    expect(
      calls,
      hasLength(2),
      reason: 'Photo filtering reuses the same source results.',
    );
    expect(tester.takeException(), isNull);
  });
  test('city scoped queries cannot share results with other areas', () {
    const query = PlaceQuery(cityId: 'pune', countryId: 'india', type: 'cafe');
    expect(query, isNot(query.copyWith(cityId: 'mumbai')));
    expect(query.copyWith(photosOnly: true).cityId, 'pune');
    expect(query.copyWith(clearCity: true).cityId, isNull);
  });
}
