import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../destinations/data/place.dart';

class PlaceQuery {
  const PlaceQuery({
    this.type = 'all',
    this.countryId,
    this.cityId,
    this.photosOnly = false,
    this.search = '',
    this.page = 1,
    this.size = 20,
  });
  final String type, search;
  final String? countryId, cityId;
  final bool photosOnly;
  final int page, size;
  PlaceQuery copyWith({
    String? type,
    String? countryId,
    String? cityId,
    bool clearCity = false,
    bool clearCountry = false,
    bool? photosOnly,
    String? search,
    int? page,
    int? size,
  }) => PlaceQuery(
    type: type ?? this.type,
    countryId: clearCountry ? null : countryId ?? this.countryId,
    cityId: clearCity ? null : cityId ?? this.cityId,
    photosOnly: photosOnly ?? this.photosOnly,
    search: search ?? this.search,
    page: page ?? this.page,
    size: size ?? this.size,
  );
  @override
  bool operator ==(Object other) =>
      other is PlaceQuery &&
      other.type == type &&
      other.countryId == countryId &&
      other.cityId == cityId &&
      other.photosOnly == photosOnly &&
      other.search == search &&
      other.page == page &&
      other.size == size;
  @override
  int get hashCode =>
      Object.hash(type, countryId, cityId, photosOnly, search, page, size);
}

class PlaceResults {
  const PlaceResults({
    required this.items,
    required this.total,
    required this.pages,
  });
  final List<TravelPlace> items;
  final int total, pages;
}

final placeCatalogueProvider = FutureProvider.autoDispose
    .family<PlaceResults, PlaceQuery>((ref, query) async {
      final cancel = CancelToken();
      ref.onDispose(cancel.cancel);
      final response = await ApiClient.dio.get(
        '/places/search',
        queryParameters: {
          'page': query.page,
          'size': query.size,
          if (query.type != 'all') 'place_type': query.type,
          if (query.countryId != null) 'country_id': query.countryId,
          if (query.cityId != null) 'city_id': query.cityId,
          if (query.photosOnly) 'has_photo': true,
          if (query.search.trim().isNotEmpty) 'search': query.search.trim(),
        },
        cancelToken: cancel,
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      final data = Map<String, dynamic>.from(response.data['data']);
      final places = (data['items'] as List)
          .map((p) => TravelPlace.fromJson(Map<String, dynamic>.from(p)))
          .toList();
      return PlaceResults(
        items: places
            .where(
              (p) =>
                  !query.photosOnly || p.imageUrl?.startsWith('http') == true,
            )
            .toList(),
        total: data['total'] as int,
        pages: data['pages'] as int,
      );
    });

const placeCategories = [
  ('all', 'All', 'Explore a little of everything'),
  ('attraction', 'Sights', 'Landmarks and local highlights'),
  ('restaurant', 'Food', 'Find somewhere to eat'),
  ('park', 'Parks', 'A little time outdoors'),
  ('cafe', 'Cafés', 'Coffee and a slower moment'),
  ('museum', 'Museums', 'Art, history and stories'),
  ('beach', 'Beaches', 'Make time for the water'),
  ('hotel', 'Stays', 'Places to stay'),
  ('heritage', 'Heritage', 'Discover the past'),
  ('viewpoint', 'Views', 'See somewhere differently'),
];

String placeTypeLabel(String type) => switch (type) {
  'restaurant' => 'Restaurant',
  'cafe' => 'Café',
  'hotel' => 'Stay',
  'worship' => 'Place of worship',
  'bus_stop' => 'Bus stop',
  _ =>
    type.isEmpty
        ? 'Place'
        : type.replaceAll('_', ' ')[0].toUpperCase() +
              type.replaceAll('_', ' ').substring(1),
};
