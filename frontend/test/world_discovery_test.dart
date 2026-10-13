import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/admin/presentation/pages/admin_discovery_panel.dart';
import 'package:trav_planner/features/destinations/data/place.dart';
import 'package:trav_planner/features/destinations/data/places_provider.dart';
import 'package:trav_planner/features/destinations/presentation/destination_details_page.dart';

void main() {
  testWidgets(
    'discover source result and open details while optional photo fails',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dio = Dio();
      final paths = <String>[];
      final place = {
        'id': 'candidate',
        'city_id': 'city',
        'name': 'Source museum',
        'place_type': 'museum',
        'provider': 'wikidata',
        'external_place_id': 'Q1234',
        'latitude': 48.85,
        'longitude': 2.35,
        'is_discovery': true,
      };
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            paths.add(options.path);
            if (options.path.endsWith('/photo')) {
              handler.reject(DioException(requestOptions: options));
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'items': [place],
                    'message': 'Source-backed places loaded.',
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
            cityPlacesProvider('city').overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: DestinationDetailsPage(
              cityId: 'city',
              name: 'City',
              discoveryClient: dio,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Discover more places'));
      await tester.tap(find.text('Discover more places'));
      await tester.pumpAndSettle();
      expect(find.text('Source museum'), findsOneWidget);
      await tester.tap(find.text('Source museum'));
      await tester.pumpAndSettle();
      expect(
        find.text('Source result · not yet reviewed by Trav'),
        findsOneWidget,
      );
      expect(find.text('Get directions'), findsOneWidget);
      expect(paths.where((p) => p.endsWith('/photo')).length, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('admin controls save free request settings', (tester) async {
    final dio = Dio();
    Map<String, dynamic>? saved;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          if (o.method == 'PUT') saved = Map<String, dynamic>.from(o.data);
          h.resolve(
            Response(
              requestOptions: o,
              data: o.path.endsWith('/candidates')
                  ? []
                  : {
                      'enabled': saved?['enabled'] ?? true,
                      'daily_calls': saved?['daily_calls'] ?? 200,
                      'calls_today': 3,
                      'cache_rows': 4,
                      'cache_bytes': 100,
                      'cache_limit_bytes': 10000,
                      'database_bytes': 10000,
                      'database_stop_bytes': 200000,
                    },
            ),
          );
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: AdminDiscoveryPanel(client: dio)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.ensureVisible(find.text('Save discovery settings'));
    await tester.tap(find.text('Save discovery settings'));
    await tester.pumpAndSettle();
    expect(saved?['enabled'], false);
    expect(saved?['daily_calls'], 200);
    expect(find.text('Discovery settings updated.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('OSM source links reject unsupported identifiers', () {
    expect(
      TravelPlace.fromJson({
        'id': 'x',
        'provider': 'osm',
        'external_place_id': 'node/123',
      }).source.toString(),
      'https://www.openstreetmap.org/node/123',
    );
    expect(
      TravelPlace.fromJson({
        'id': 'x',
        'provider': 'osm',
        'external_place_id': 'https://example.com',
      }).source,
      isNull,
    );
  });
}
