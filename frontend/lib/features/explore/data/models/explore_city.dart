class ExploreCity {
  final String id;
  final String countryId;
  final String stateId;
  final String name;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const ExploreCity({
    required this.id,
    required this.countryId,
    required this.stateId,
    required this.name,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  factory ExploreCity.fromJson(Map<String, dynamic> json) {
    return ExploreCity(
      id: json['id']?.toString() ?? '',
      countryId: json['country_id']?.toString() ?? '',
      stateId: json['state_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}

class ExploreCitySearchResult {
  final List<ExploreCity> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  const ExploreCitySearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory ExploreCitySearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return ExploreCitySearchResult(
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      ExploreCity.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 20,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
    );
  }
}
