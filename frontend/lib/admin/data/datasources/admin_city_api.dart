import '../../../../core/network/api_client.dart';
import '../models/admin_city_model.dart';

class AdminCityApi {
  // ==========================================================
  // Search / Paginated Cities
  // ==========================================================

  Future<AdminCitySearchResult> searchCities({
    int page = 1,
    int size = 50,
    String? search,
    String? countryId,
    String? stateId,
  }) async {
    final queryParameters = <String, dynamic>{'page': page, 'size': size};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (countryId != null && countryId.isNotEmpty) {
      queryParameters['country_id'] = countryId;
    }

    if (stateId != null && stateId.isNotEmpty) {
      queryParameters['state_id'] = stateId;
    }

    final response = await ApiClient.dio.get(
      '/cities/search',
      queryParameters: queryParameters,
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid city search response.');
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid city search data.');
    }

    return AdminCitySearchResult.fromJson(data);
  }

  // ==========================================================
  // Get all cities
  //
  // Kept for compatibility with existing code.
  // Do NOT use this for the Admin Cities list.
  // ==========================================================

  Future<List<AdminCityModel>> getAllCities() async {
    final response = await ApiClient.dio.get('/cities/');

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid city response from server.');
    }

    final items = data['data'];

    if (items is! List) {
      throw Exception('Invalid city data from server.');
    }

    return items
        .map((item) => AdminCityModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ==========================================================
  // Create city
  // ==========================================================

  Future<AdminCityModel> createCity({
    required String countryId,
    required String stateId,
    required String name,
    double? latitude,
    double? longitude,
    bool isActive = true,
  }) async {
    final response = await ApiClient.dio.post(
      '/cities/',
      data: {
        'country_id': countryId,
        'state_id': stateId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': isActive,
      },
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid city response from server.');
    }

    final cityData = data['data'];

    if (cityData is! Map<String, dynamic>) {
      throw Exception('Invalid city data from server.');
    }

    return AdminCityModel.fromJson(cityData);
  }

  // ==========================================================
  // Update city
  // ==========================================================

  Future<AdminCityModel> updateCity({
    required String id,
    required String countryId,
    required String stateId,
    required String name,
    double? latitude,
    double? longitude,
    bool isActive = true,
  }) async {
    final response = await ApiClient.dio.put(
      '/cities/$id',
      data: {
        'country_id': countryId,
        'state_id': stateId,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'is_active': isActive,
      },
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid city response from server.');
    }

    final cityData = data['data'];

    if (cityData is! Map<String, dynamic>) {
      throw Exception('Invalid city data from server.');
    }

    return AdminCityModel.fromJson(cityData);
  }

  // ==========================================================
  // Delete city
  // ==========================================================

  Future<void> deleteCity(String id) async {
    await ApiClient.dio.delete('/cities/$id');
  }
}
