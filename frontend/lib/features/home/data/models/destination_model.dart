class DestinationModel {
  final String id;
  final String cityId;
  final String title;
  final String slug;
  final String country;
  final String? shortDescription;
  final String? description;
  final String? image;
  final double? latitude;
  final double? longitude;
  final bool isFeatured;
  final bool isActive;

  const DestinationModel({
    required this.id,
    required this.cityId,
    required this.title,
    required this.slug,
    required this.country,
    this.shortDescription,
    this.description,
    this.image,
    this.latitude,
    this.longitude,
    required this.isFeatured,
    required this.isActive,
  });

  factory DestinationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DestinationModel(
      id: json["id"] as String,
      cityId: json["city_id"] as String,
      title: json["name"] as String,
      slug: json["slug"] as String,
      country: json["country"] as String? ?? "",
      shortDescription: json["short_description"] as String?,
      description: json["description"] as String?,
      image: json["image_url"] as String?,

      latitude: _parseDouble(json["latitude"]),
      longitude: _parseDouble(json["longitude"]),

      isFeatured: json["is_featured"] as bool? ?? false,
      isActive: json["is_active"] as bool? ?? true,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}