class AdminDestinationModel {
  final String id;
  final String cityId;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminDestinationModel({
    required this.id,
    required this.cityId,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.isFeatured,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory AdminDestinationModel.fromJson(Map<String, dynamic> json) {
    return AdminDestinationModel(
      id: json['id'] as String,
      cityId: json['city_id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
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

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
