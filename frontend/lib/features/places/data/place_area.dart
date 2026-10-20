import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../destinations/data/place.dart';

/// A public destination context, never a device's private GPS position.
class PlaceArea {
  const PlaceArea({
    this.cityId,
    this.sourceId,
    required this.name,
    this.regionName = '',
    this.countryName = '',
    this.countryId,
    this.countryCode,
    this.latitude,
    this.longitude,
  });
  final String? cityId, sourceId, countryId, countryCode;
  final String name, regionName, countryName;
  final double? latitude, longitude;
  String get subtitle =>
      [regionName, countryName].where((s) => s.isNotEmpty).join(' · ');
  PlaceArea resolved(Map<String, dynamic> row) => PlaceArea(
    cityId: row['id'].toString(),
    name: row['name']?.toString() ?? name,
    regionName: regionName,
    countryName: countryName,
    countryId: row['country_id']?.toString() ?? countryId,
    countryCode: countryCode,
    latitude: validCoordinates(row['latitude'], row['longitude'])?.latitude,
    longitude: validCoordinates(row['latitude'], row['longitude'])?.longitude,
  );
}

final chosenPlaceAreaProvider = StateProvider<PlaceArea?>((ref) => null);
final placeAreaApiProvider = Provider<PlaceAreaApi>((ref) => PlaceAreaApi());

class PlaceAreaSearch {
  const PlaceAreaSearch(this.query, {this.countryId});
  final String query;
  final String? countryId;
  @override
  bool operator ==(Object other) =>
      other is PlaceAreaSearch &&
      other.query == query &&
      other.countryId == countryId;
  @override
  int get hashCode => Object.hash(query, countryId);
}

class PlaceAreaResults {
  const PlaceAreaResults(this.items, {this.notice});
  final List<PlaceArea> items;
  final String? notice;
}

final areaSearchProvider = FutureProvider.autoDispose
    .family<PlaceAreaResults, PlaceAreaSearch>((ref, request) {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      return ref
          .read(placeAreaApiProvider)
          .search(request.query, countryId: request.countryId, cancel: cancel);
    });

class PlaceAreaApi {
  PlaceAreaApi({Dio? client}) : client = client ?? ApiClient.dio;
  final Dio client;
  List<Map<String, dynamic>>? _countries;
  final Map<String, Map<String, String>> _regions = {};
  Future<PlaceAreaResults> search(
    String query, {
    String? countryId,
    CancelToken? cancel,
  }) async {
    if (query.trim().length < 2) return const PlaceAreaResults([]);
    try {
      _countries ??=
          ((await client.get(
                    '/countries/active',
                    cancelToken: cancel,
                  )).data['data']
                  as List)
              .map((r) => Map<String, dynamic>.from(r))
              .toList();
    } catch (_) {
      /* Locations remain searchable when labels cannot load. */
    }
    final countries = {
      for (final c in _countries ?? <Map<String, dynamic>>[])
        c['id'].toString(): c,
    };
    final iso = countries[countryId]?['iso2'];
    final notices = <String>[];
    final results = await Future.wait([
      _safe(
        '/cities/search',
        {'search': query.trim(), 'size': 20, 'country_id': ?countryId},
        cancel,
        notices,
      ),
      // Country UUIDs are never sent as ISO codes to the settlement index.
      if (countryId == null || iso != null)
        _safe(
          '/discovery/locations',
          {'q': query.trim(), 'country': ?iso},
          cancel,
          notices,
        ),
    ]);
    final existing = (results.first?['data']?['items'] as List? ?? [])
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    final indexed =
        (results.length > 1 ? (results[1]?['items'] as List?) : null) ?? [];
    // Region labels are fetched once per matched country, with a bounded fan-out.
    final ids = existing.map((r) => r['country_id'].toString()).toSet().take(4);
    await Future.wait(
      ids.map((id) async {
        if (_regions.containsKey(id)) return;
        try {
          final r = await client.get(
            '/states/country/$id',
            cancelToken: cancel,
          );
          _regions[id] = {
            for (final s in r.data['data'] as List)
              s['id'].toString(): s['name'].toString(),
          };
        } catch (_) {
          /* Country and coordinates still distinguish candidates. */
        }
      }),
    );
    final items = <PlaceArea>[];
    for (final r in indexed) {
      final p = validCoordinates(r['latitude'], r['longitude']);
      final country = countries.values
          .where((c) => c['iso2'] == r['country'])
          .firstOrNull;
      items.add(
        PlaceArea(
          sourceId: r['id'].toString(),
          name: r['name'].toString(),
          regionName: r['region_name']?.toString() ?? '',
          countryName: r['country_name']?.toString() ?? '',
          countryCode: r['country']?.toString(),
          countryId: country?['id']?.toString(),
          latitude: p?.latitude,
          longitude: p?.longitude,
        ),
      );
    }
    for (final r in existing) {
      final p = validCoordinates(r['latitude'], r['longitude']);
      final cid = r['country_id'].toString();
      final matched = items.indexWhere(
        (a) =>
            a.countryId == cid &&
            a.name.toLowerCase() == r['name'].toString().toLowerCase() &&
            p != null &&
            a.latitude != null &&
            a.longitude != null &&
            (a.latitude! - p.latitude).abs() < .01 &&
            (a.longitude! - p.longitude).abs() < .01,
      );
      final item = PlaceArea(
        cityId: r['id'].toString(),
        name: r['name'].toString(),
        regionName:
            _regions[cid]?[r['state_id']] ??
            (matched >= 0 ? items[matched].regionName : ''),
        countryName: countries[cid]?['name']?.toString() ?? '',
        countryId: cid,
        countryCode: countries[cid]?['iso2']?.toString(),
        latitude: p?.latitude,
        longitude: p?.longitude,
      );
      if (matched >= 0) {
        items[matched] = item;
      } else {
        items.add(item);
      }
    }
    return PlaceAreaResults(
      items,
      notice: notices.isEmpty
          ? null
          : 'Some location sources are unavailable. Available matches are shown.',
    );
  }

  Future<Map<String, dynamic>?> _safe(
    String path,
    Map<String, dynamic> params,
    CancelToken? cancel,
    List<String> notices,
  ) async {
    try {
      return Map<String, dynamic>.from(
        (await client.get(
          path,
          queryParameters: params,
          cancelToken: cancel,
        )).data,
      );
    } catch (_) {
      notices.add(path);
      return null;
    }
  }

  Future<PlaceArea> open(PlaceArea area) async {
    if (area.cityId != null) return area;
    return area.resolved(
      Map<String, dynamic>.from(
        (await client.post('/discovery/locations/${area.sourceId}/open')).data,
      ),
    );
  }
}
