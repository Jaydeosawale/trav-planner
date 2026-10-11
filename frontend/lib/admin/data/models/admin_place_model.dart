class AdminPlaceModel {
  final String id;
  final String cityId;
  final String? categoryId;

  final String name;
  final String slug;
  final String placeType;

  final String? shortDescription;
  final String? description;

  final String? address;
  final String? locality;
  final String? postalCode;

  final double? latitude;
  final double? longitude;

  final String? imageUrl;

  final String? provider;
  final String? externalPlaceId;

  final double? rating;
  final int? priceLevel;

  final bool isFeatured;
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminPlaceModel({
    required this.id,
    required this.cityId,
    this.categoryId,
    required this.name,
    required this.slug,
    required this.placeType,
    this.shortDescription,
    this.description,
    this.address,
    this.locality,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.provider,
    this.externalPlaceId,
    this.rating,
    this.priceLevel,
    required this.isFeatured,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminPlaceModel.fromJson(Map<String, dynamic> json) {
    return AdminPlaceModel(
      id: json['id'] as String,
      cityId: json['city_id'] as String,
      categoryId: json['category_id'] as String?,

      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      placeType: json['place_type'] as String? ?? '',

      shortDescription: json['short_description'] as String?,

      description: json['description'] as String?,

      address: json['address'] as String?,

      locality: json['locality'] as String?,

      postalCode: json['postal_code'] as String?,

      latitude: _parseDouble(json['latitude']),

      longitude: _parseDouble(json['longitude']),

      imageUrl: json['image_url'] as String?,

      provider: json['provider'] as String?,

      externalPlaceId: json['external_place_id'] as String?,

      rating: _parseDouble(json['rating']),

      priceLevel: _parseInt(json['price_level']),

      isFeatured: json['is_featured'] as bool? ?? false,

      isActive: json['is_active'] as bool? ?? true,

      createdAt: _parseDate(json['created_at']),

      updatedAt: _parseDate(json['updated_at']),
    );
  }

  // ==========================================================
  // Helpers
  // ==========================================================

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
