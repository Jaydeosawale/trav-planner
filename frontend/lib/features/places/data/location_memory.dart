import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:latlong2/latlong.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../destinations/data/place.dart';
import 'place_area.dart';
import 'nearby_origin.dart';
import 'current_location.dart';

final locationMemoryStoreProvider = Provider<LocationMemoryStore>(
  (ref) => LocationMemoryStore(),
);

class LocationMemoryStore {
  final _storage = const FlutterSecureStorage();
  Future<Map<String, dynamic>?> load(String account) async {
    final raw = await _storage.read(key: 'trav_location_v1_$account');
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> save(String account, Map<String, dynamic>? value) =>
      value == null
      ? _storage.delete(key: 'trav_location_v1_$account')
      : _storage.write(
          key: 'trav_location_v1_$account',
          value: jsonEncode(value),
        );
}

/// One approximate area per account on this device; AI sharing is explicit.
final locationMemoryProvider = Provider<void>((ref) {
  final account = ref.watch(authProvider.select((s) => s.user?.id));
  if (account == null) return;
  final store = ref.read(locationMemoryStoreProvider);
  var active = true, restoring = false;
  var revision = 0;
  String? mode;
  var writes = Future<void>.value();
  ref.onDispose(() => active = false);
  void save(Map<String, dynamic>? data) {
    revision++;
    writes = writes
        .then((_) => store.save(account, data))
        .catchError((Object _) {});
  }

  ref.listen(chosenPlaceAreaProvider, (_, area) {
    if (!active ||
        ref.read(authProvider).user?.id != account ||
        restoring ||
        area == null) {
      return;
    }
    mode = 'town';
    ref.read(aiLocationEnabledProvider.notifier).state = false;
    ref.read(nearbyOriginProvider.notifier).state = null;
    save({
      'mode': mode,
      'city_id': area.cityId,
      'name': area.name,
      'region': area.regionName,
      'country': area.countryName,
      'country_id': area.countryId,
      'country_code': area.countryCode,
      'latitude': area.latitude,
      'longitude': area.longitude,
    });
  });
  ref.listen(nearbyOriginProvider, (_, point) {
    if (!active || ref.read(authProvider).user?.id != account || restoring) {
      return;
    }
    if (point == null) {
      if (mode == 'gps') {
        mode = null;
        save(null);
      }
      return;
    }
    mode = 'gps';
    save({
      'mode': mode,
      'ai_shared': ref.read(aiLocationEnabledProvider),
      'latitude': double.parse(point.latitude.toStringAsFixed(3)),
      'longitude': double.parse(point.longitude.toStringAsFixed(3)),
    });
  });
  ref.listen(aiLocationEnabledProvider, (_, enabled) {
    if (!active ||
        restoring ||
        ref.read(authProvider).user?.id != account ||
        mode != 'gps') {
      return;
    }
    final point = ref.read(nearbyOriginProvider);
    if (point == null) return;
    save({
      'mode': 'gps',
      'ai_shared': enabled,
      'latitude': double.parse(point.latitude.toStringAsFixed(3)),
      'longitude': double.parse(point.longitude.toStringAsFixed(3)),
    });
  });
  Future<void>(() async {
    try {
      final data = await store.load(account);
      if (!active || revision != 0 || data == null) return;
      final point = validCoordinates(data['latitude'], data['longitude']);
      restoring = true;
      if (data['mode'] == 'gps' && point != null) {
        mode = 'gps';
        ref.read(nearbyOriginProvider.notifier).state = LatLng(
          point.latitude,
          point.longitude,
        );
        ref.read(aiLocationEnabledProvider.notifier).state =
            data['ai_shared'] == true;
      } else if (data['mode'] == 'town' && data['name'] is String) {
        mode = 'town';
        ref.read(chosenPlaceAreaProvider.notifier).state = PlaceArea(
          cityId: data['city_id'] as String?,
          name: data['name'],
          regionName: data['region'] as String? ?? '',
          countryName: data['country'] as String? ?? '',
          countryId: data['country_id'] as String?,
          countryCode: data['country_code'] as String?,
          latitude: point?.latitude,
          longitude: point?.longitude,
        );
      }
    } catch (_) {
      // Storage failure must never block manual search or device permission.
    } finally {
      restoring = false;
    }
  });
});
