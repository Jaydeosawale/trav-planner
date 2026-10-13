import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trav_planner/features/explore/presentation/pages/world_locations_panel.dart';
import 'package:trav_planner/features/destinations/data/places_provider.dart';

void main() {
  testWidgets('search smaller towns and open resolved destination', (
    tester,
  ) async {
    final dio = Dio();
    final calls = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          calls.add(o.path);
          if (o.path.startsWith('/discovery/cities/')) {
            h.resolve(Response(requestOptions: o, data: {'items': []}));
          } else if (o.method == 'GET') {
            expect(o.queryParameters['q'], 'Panchgani');
            expect(o.queryParameters['country'], 'IN');
            h.resolve(
              Response(
                requestOptions: o,
                data: {
                  'items': [
                    {
                      'id': '123',
                      'name': 'Panchgani',
                      'region_name': 'Maharashtra',
                      'country_name': 'India',
                      'latitude': 17.9,
                      'longitude': 73.8,
                    },
                  ],
                },
              ),
            );
          } else {
            h.resolve(
              Response(
                requestOptions: o,
                data: {
                  'id': 'resolved',
                  'name': 'Panchgani',
                  'latitude': 17.9,
                  'longitude': 73.8,
                  'is_active': true,
                },
              ),
            );
          }
        },
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityPlacesProvider('resolved').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorldLocationsPanel(
                query: 'Panchgani',
                country: 'IN',
                client: dio,
              ),
            ),
          ),
        ),
      ),
    );
    expect(calls, isEmpty);
    await tester.tap(find.text('Search more locations'));
    await tester.pumpAndSettle();
    expect(find.text('Panchgani'), findsOneWidget);
    await tester.tap(find.text('Panchgani'));
    await tester.pumpAndSettle();
    expect(calls, [
      '/discovery/locations',
      '/discovery/locations/123/open',
      '/discovery/cities/resolved',
    ]);
    expect(find.text('Find your kind of Panchgani.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
