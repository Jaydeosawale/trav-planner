import '../../../../core/network/api_client.dart';
import '../models/admin_destination_model.dart';

class AdminDestinationApi {
  // ==========================================================
  // Get all destinations
  // ==========================================================

  Future<List<AdminDestinationModel>> getAllDestinations() async {
    final response = await ApiClient.dio.get('/destinations/');

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid destination response from server.');
    }

    final items = data['data'];

    if (items is! List) {
      throw Exception('Invalid destination data from server.');
    }

    return items
        .map(
          (item) =>
              AdminDestinationModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // ==========================================================
  // Get destination by ID
  // ==========================================================

  Future<AdminDestinationModel> getDestination(String id) async {
    final response = await ApiClient.dio.get('/destinations/$id');

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid destination response from server.');
    }

    return AdminDestinationModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==========================================================
  // Create destination
  // ==========================================================

  Future<AdminDestinationModel> createDestination({
    required String cityId,
    required String name,
    required String slug,
    String? shortDescription,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    bool isFeatured = false,
  }) async {
    final response = await ApiClient.dio.post(
      '/destinations/',
      data: {
        'city_id': cityId,
        'name': name,
        'slug': slug,
        'short_description': shortDescription,
        'description': description,
        'image_url': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'is_featured': isFeatured,
      },
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid destination response from server.');
    }

    return AdminDestinationModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==========================================================
  // Update destination
  // ==========================================================

  Future<AdminDestinationModel> updateDestination({
    required String id,
    String? cityId,
    String? name,
    String? slug,
    String? shortDescription,
    String? description,
    String? imageUrl,
    double? latitude,
    double? longitude,
    bool? isFeatured,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};

    if (cityId != null) {
      payload['city_id'] = cityId;
    }

    if (name != null) {
      payload['name'] = name;
    }

    if (slug != null) {
      payload['slug'] = slug;
    }

    if (shortDescription != null) {
      payload['short_description'] = shortDescription;
    }

    if (description != null) {
      payload['description'] = description;
    }

    if (imageUrl != null) {
      payload['image_url'] = imageUrl;
    }

    if (latitude != null) {
      payload['latitude'] = latitude;
    }

    if (longitude != null) {
      payload['longitude'] = longitude;
    }

    if (isFeatured != null) {
      payload['is_featured'] = isFeatured;
    }

    if (isActive != null) {
      payload['is_active'] = isActive;
    }

    final response = await ApiClient.dio.patch(
      '/destinations/$id',
      data: payload,
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid destination response from server.');
    }

    return AdminDestinationModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ==========================================================
  // Delete destination
  // ==========================================================

  Future<void> deleteDestination(String id) async {
    await ApiClient.dio.delete('/destinations/$id');
  }
}
