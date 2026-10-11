class AdminCityModel {
  final String id;
  final String countryId;
  final String stateId;
  final String name;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const AdminCityModel({
    required this.id,
    required this.countryId,
    required this.stateId,
    required this.name,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  factory AdminCityModel.fromJson(Map<String, dynamic> json) {
    return AdminCityModel(
      id: json['id'] as String,
      countryId: json['country_id'] as String,
      stateId: json['state_id'] as String,
      name: json['name'] as String? ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}

class AdminCitySearchResult {
  final List<AdminCityModel> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  const AdminCitySearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  factory AdminCitySearchResult.fromJson(Map<String, dynamic> json) {
    final items = json['items'];

    return AdminCitySearchResult(
      items: items is List
          ? items
                .map(
                  (item) =>
                      AdminCityModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 50,
      pages: (json['pages'] as num?)?.toInt() ?? 0,
    );
  }
}
