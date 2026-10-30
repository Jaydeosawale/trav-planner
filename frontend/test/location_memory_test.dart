import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trav_planner/features/auth/presentation/providers/auth_provider.dart';
import 'package:trav_planner/features/places/data/location_memory.dart';
import 'package:trav_planner/features/places/data/nearby_origin.dart';
import 'package:trav_planner/features/places/data/place_area.dart';
import 'package:trav_planner/features/places/data/current_location.dart';
import 'saved_places_test.dart' show TestAuth;

class MemoryLocations extends LocationMemoryStore {
  final rows = <String, Map<String, dynamic>>{};
  Completer<Map<String, dynamic>?>? pending;
  @override
  Future<Map<String, dynamic>?> load(String account) async =>
      pending == null ? rows[account] : pending!.future;
  @override
  Future<void> save(String account, Map<String, dynamic>? value) async {
    if (value == null) {
      rows.remove(account);
    } else {
      rows[account] = Map.of(value);
    }
  }
}

Future<void> flushMemory() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

ProviderContainer memoryContainer(MemoryLocations store) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(TestAuth.new),
      locationMemoryStoreProvider.overrideWithValue(store),
    ],
  );
  container.read(locationMemoryProvider);
  return container;
}

void main() {
  test(
    'Nearby GPS survives reopening without automatically enabling AI sharing',
    () async {
      final store = MemoryLocations();
      var container = memoryContainer(store);
      container.read(nearbyOriginProvider.notifier).state = const LatLng(
        18.520432,
        73.856742,
      );
      await flushMemory();
      expect(store.rows['one']!['latitude'], 18.52);
      container.dispose();
      container = memoryContainer(store);
      addTearDown(container.dispose);
      await flushMemory();
      expect(container.read(nearbyOriginProvider)!.longitude, 73.857);
      expect(container.read(aiLocationEnabledProvider), isFalse);
    },
  );
  test(
    'A newly entered town replaces GPS and saved areas stay account-specific',
    () async {
      final store = MemoryLocations();
      final container = memoryContainer(store);
      addTearDown(container.dispose);
      container.read(nearbyOriginProvider.notifier).state = const LatLng(
        18.52,
        73.85,
      );
      container.read(chosenPlaceAreaProvider.notifier).state = const PlaceArea(
        cityId: 'paris',
        name: 'Paris',
        latitude: 48.86,
        longitude: 2.35,
      );
      await flushMemory();
      expect(store.rows['one']!['mode'], 'town');
      expect(container.read(nearbyOriginProvider), isNull);
      (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
      container.read(locationMemoryProvider);
      await flushMemory();
      expect(container.read(chosenPlaceAreaProvider), isNull);
      expect(container.read(nearbyOriginProvider), isNull);
      (container.read(authProvider.notifier) as TestAuth).switchAccount('one');
      container.read(locationMemoryProvider);
      await flushMemory();
      expect(container.read(chosenPlaceAreaProvider)!.name, 'Paris');
    },
  );
  test(
    'A delayed saved-area load never overwrites a fresh user selection',
    () async {
      final store = MemoryLocations()
        ..pending = Completer<Map<String, dynamic>?>();
      final container = memoryContainer(store);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);
      container.read(chosenPlaceAreaProvider.notifier).state = const PlaceArea(
        cityId: 'pune',
        name: 'Pune',
      );
      store.pending!.complete({
        'mode': 'gps',
        'latitude': 40.0,
        'longitude': 50.0,
      });
      await flushMemory();
      expect(container.read(chosenPlaceAreaProvider)!.name, 'Pune');
      expect(container.read(nearbyOriginProvider), isNull);
    },
  );
  test(
    'Switching accounts does not erase the previous account GPS choice',
    () async {
      final store = MemoryLocations();
      final container = memoryContainer(store);
      addTearDown(container.dispose);
      container.read(nearbyOriginProvider.notifier).state = const LatLng(
        18.52,
        73.85,
      );
      await flushMemory();
      (container.read(authProvider.notifier) as TestAuth).switchAccount('two');
      container.read(locationMemoryProvider);
      await flushMemory();
      expect(container.read(nearbyOriginProvider), isNull);
      expect(store.rows['one']!['mode'], 'gps');
      (container.read(authProvider.notifier) as TestAuth).switchAccount('one');
      container.read(locationMemoryProvider);
      await flushMemory();
      expect(container.read(nearbyOriginProvider)!.latitude, 18.52);
    },
  );
  test('Explicit AI-location sharing is remembered until removed', () async {
    final store = MemoryLocations();
    var container = memoryContainer(store);
    container.read(nearbyOriginProvider.notifier).state = const LatLng(
      18.52,
      73.85,
    );
    container.read(aiLocationEnabledProvider.notifier).state = true;
    await flushMemory();
    container.dispose();
    container = memoryContainer(store);
    addTearDown(container.dispose);
    await flushMemory();
    expect(container.read(aiLocationEnabledProvider), isTrue);
    container.read(aiLocationEnabledProvider.notifier).state = false;
    container.read(nearbyOriginProvider.notifier).state = null;
    await flushMemory();
    expect(store.rows['one'], isNull);
  });
}
