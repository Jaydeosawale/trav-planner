import 'package:latlong2/latlong.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trav_planner/features/ai/presentation/pages/structured_plan_page.dart';
import 'package:trav_planner/features/explore/presentation/pages/nearby_places_page.dart';
import 'package:trav_planner/features/booking/presentation/pages/booking_links_page.dart';

class NearbyTestAuth extends AuthNotifier {
  @override
  AuthState build() => AuthState.authenticated(
    user: UserModel(
      id: 'test-user',
      email: 'nearby@example.test',
      fullName: 'Nearby tester',
      isActive: true,
      createdAt: DateTime(2026),
      role: 'user',
    ),
  );
}

void main() {
  testWidgets('daily plan requires review and saves only selected activities', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio();
    Map? saved;
    var saves = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          dynamic data;
          if (o.path == '/cities/search') {
            data = {
              'data': {
                'items': [
                  {
                    'id': 'pune',
                    'name': 'Pune',
                    'country_id': 'india',
                    'latitude': 18.52,
                    'longitude': 73.85,
                  },
                ],
              },
            };
          } else if (o.path == '/countries/active') {
            data = {
              'data': [
                {'id': 'india', 'name': 'India'},
              ],
            };
          } else if (o.path.endsWith('/save')) {
            saves++;
            saved = Map.from(o.data);
            data = {'trip_id': 'saved-trip'};
          } else {
            data = {
              'id': 'draft',
              'city_name': 'Pune',
              'request': o.data,
              'places': {
                'museum': {
                  'id': 'museum',
                  'city_id': 'pune',
                  'name': 'Museum',
                  'place_type': 'museum',
                  'latitude': 18.52,
                  'longitude': 73.85,
                },
              },
              'plan': {
                'title': 'Pune trip',
                'summary': 'Relaxed days',
                'days': [
                  {
                    'title': 'Explore',
                    'activities': [
                      {
                        'title': 'Museum',
                        'place_id': 'museum',
                        'kind': 'activity',
                        'duration_minutes': 90,
                        'notes': 'Check hours',
                      },
                      {'title': 'Rest', 'kind': 'rest', 'duration_minutes': 60},
                    ],
                  },
                  {
                    'title': 'Walk',
                    'activities': [
                      {
                        'title': 'Local walk',
                        'kind': 'activity',
                        'duration_minutes': 60,
                      },
                    ],
                  },
                  {
                    'title': 'Relax',
                    'activities': [
                      {
                        'title': 'Free morning',
                        'kind': 'rest',
                        'duration_minutes': 60,
                      },
                    ],
                  },
                ],
              },
            };
          }
          h.resolve(Response(requestOptions: o, data: data));
        },
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: StructuredPlanPage(client: dio)),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Pune');
    await tester.tap(find.text('Find destination'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Pune'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Generate daily plan'));
    await tester.tap(find.text('Generate daily plan'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.text('Review your daily plan'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(CheckboxListTile, 'Rest'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Rest'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save reviewed itinerary'));
    await tester.tap(find.text('Save reviewed itinerary'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(saved!['selected'], isNot(contains('0:1')));
    expect(find.text('Open saved trip'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('normal nearby city search makes no AI call', (tester) async {
    final dio = Dio();
    final paths = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          paths.add(o.path);
          dynamic data;
          if (o.path == '/cities/search') {
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
          } else if (o.path == '/countries/active') {
            data = {
              'data': [
                {'id': 'india', 'name': 'India', 'iso2': 'IN'},
              ],
            };
          } else if (o.path == '/discovery/locations') {
            data = {
              'items': [
                {
                  'id': 'small-town',
                  'name': 'Pune district town',
                  'country': 'IN',
                  'country_name': 'India',
                  'region_name': 'Maharashtra',
                  'latitude': 18.6,
                  'longitude': 73.9,
                },
              ],
            };
          } else if (o.path == '/states/country/india') {
            data = {
              'data': [
                {'id': 'mh', 'name': 'Maharashtra'},
              ],
            };
          } else {
            expect(o.path, '/discovery/nearby');
            expect(o.method, 'POST');
            expect(o.data['radius_km'], 5);
            data = {
              'items': [
                {
                  'id': 'museum',
                  'city_id': 'pune',
                  'name': 'Nearby museum',
                  'place_type': 'museum',
                  'distance_km': 0.4,
                },
              ],
              'message': 'Stored places',
              'distance_note': 'Straight-line distances',
            };
          }
          h.resolve(Response(requestOptions: o, data: data));
        },
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authProvider.overrideWith(NearbyTestAuth.new)],
        child: MaterialApp(home: NearbyPlacesPage(client: dio)),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Pune');
    await tester.tap(find.byTooltip('Find location'));
    await tester.pumpAndSettle();
    expect(find.text('Pune district town'), findsOneWidget);
    expect(find.text('Maharashtra · India'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(ListTile, 'Pune'));
    await tester.pumpAndSettle();
    expect(find.text('Nearby museum'), findsOneWidget);
    expect(paths, contains('/discovery/nearby'));
    expect(paths, contains('/discovery/locations'));
    expect(paths.any((p) => p.startsWith('/ai')), isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('direct flight and train options fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: BookingLinksPage()));
    expect(find.text('Search flights'), findsOneWidget);
    await tester.tap(find.text('Trains'));
    await tester.pumpAndSettle();
    expect(find.text('Continue to IRCTC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'An already shared location opens the chosen day category automatically',
    (tester) async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              requests.add(o);
              h.resolve(
                Response(
                  requestOptions: o,
                  data: {
                    'items': [],
                    'message': 'No cafés in this area',
                    'distance_note': 'Straight-line distances',
                  },
                ),
              );
            },
          ),
        );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authProvider.overrideWith(NearbyTestAuth.new)],
          child: MaterialApp(
            home: NearbyPlacesPage(
              client: dio,
              initialKind: 'cafe',
              initialOrigin: const LatLng(18.52, 73.85),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests.length, 1);
      expect(requests.single.path, '/discovery/nearby');
      expect(requests.single.data['kind'], 'cafe');
      expect(requests.single.data['latitude'], 18.52);
      expect(tester.takeException(), isNull);
    },
  );
}
