import '../../../core/network/api_client.dart';
import '../models/admin_place_model.dart';

class AdminPlaceApi {
  // ==========================================================
  // Get all places for Admin
  // ==========================================================

  Future<List<AdminPlaceModel>> getPlaces() async {
    final response = await ApiClient.dio.get('/admin/places/');

    final data = response.data;

    final List<dynamic> items = data['data'] as List<dynamic>? ?? [];

    return items
        .map((item) => AdminPlaceModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ==========================================================
  // Get place by ID
  // ==========================================================

  Future<AdminPlaceModel> getPlace(String placeId) async {
    final response = await ApiClient.dio.get('/admin/places/$placeId');

    final data = response.data;

    return AdminPlaceModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==========================================================
  // Create Place
  // ==========================================================

  Future<AdminPlaceModel> createPlace({
    required String cityId,
    String? categoryId,
    required String name,
    required String slug,
    required String placeType,
    String? shortDescription,
    String? description,
    String? address,
    String? locality,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? provider,
    String? externalPlaceId,
    double? rating,
    int? priceLevel,
    bool isFeatured = false,
  }) async {
    final response = await ApiClient.dio.post(
      '/admin/places/',
      data: {
        'city_id': cityId,
        'category_id': categoryId,
        'name': name,
        'slug': slug,
        'place_type': placeType,
        'short_description': shortDescription,
        'description': description,
        'address': address,
        'locality': locality,
        'postal_code': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl,
        'provider': provider,
        'external_place_id': externalPlaceId,
        'rating': rating,
        'price_level': priceLevel,
        'is_featured': isFeatured,
      },
    );

    final data = response.data;

    return AdminPlaceModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==========================================================
  // Update Place
  // ==========================================================

  Future<AdminPlaceModel> updatePlace({
    required String placeId,
    String? cityId,
    String? categoryId,
    String? name,
    String? slug,
    String? placeType,
    String? shortDescription,
    String? description,
    String? address,
    String? locality,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? provider,
    String? externalPlaceId,
    double? rating,
    int? priceLevel,
    bool? isFeatured,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};

    if (cityId != null) {
      payload['city_id'] = cityId;
    }

    if (categoryId != null) {
      payload['category_id'] = categoryId;
    }

    if (name != null) {
      payload['name'] = name;
    }

    if (slug != null) {
      payload['slug'] = slug;
    }

    if (placeType != null) {
      payload['place_type'] = placeType;
    }

    if (shortDescription != null) {
      payload['short_description'] = shortDescription;
    }

    if (description != null) {
      payload['description'] = description;
    }

    if (address != null) {
      payload['address'] = address;
    }

    if (locality != null) {
      payload['locality'] = locality;
    }

    if (postalCode != null) {
      payload['postal_code'] = postalCode;
    }

    if (latitude != null) {
      payload['latitude'] = latitude;
    }

    if (longitude != null) {
      payload['longitude'] = longitude;
    }

    if (imageUrl != null) {
      payload['image_url'] = imageUrl;
    }

    if (provider != null) {
      payload['provider'] = provider;
    }

    if (externalPlaceId != null) {
      payload['external_place_id'] = externalPlaceId;
    }

    if (rating != null) {
      payload['rating'] = rating;
    }

    if (priceLevel != null) {
      payload['price_level'] = priceLevel;
    }

    if (isFeatured != null) {
      payload['is_featured'] = isFeatured;
    }

    if (isActive != null) {
      payload['is_active'] = isActive;
    }

    final response = await ApiClient.dio.patch(
      '/admin/places/$placeId',
      data: payload,
    );

    final data = response.data;

    return AdminPlaceModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==========================================================
  // Delete Place
  // ==========================================================

  Future<void> deletePlace(String placeId) async {
    await ApiClient.dio.delete('/admin/places/$placeId');
  }
}
