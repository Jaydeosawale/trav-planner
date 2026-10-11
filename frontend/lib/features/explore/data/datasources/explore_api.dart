import '../../../../core/network/api_client.dart';

import '../models/explore_city.dart';
import '../models/explore_country.dart';
import '../models/explore_state.dart';

class ExploreApi {
  ExploreApi._();

  static final ExploreApi instance = ExploreApi._();

  // ==========================================================
  // Countries
  // ==========================================================

  Future<List<ExploreCountry>> getActiveCountries() async {
    final response = await ApiClient.dio.get('/countries/active');

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid country response from server.');
    }

    final data = responseData['data'];

    if (data is! List) {
      throw Exception('Invalid country data from server.');
    }

    return data
        .whereType<Map>()
        .map((item) => ExploreCountry.fromJson(Map<String, dynamic>.from(item)))
        .where((country) => country.isActive)
        .toList();
  }

  // ==========================================================
  // States by country
  // ==========================================================

  Future<List<ExploreState>> getStatesByCountry(String countryId) async {
    final response = await ApiClient.dio.get('/states/country/$countryId');

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid state response from server.');
    }

    final data = responseData['data'];

    if (data is! List) {
      throw Exception('Invalid state data from server.');
    }

    return data
        .whereType<Map>()
        .map((item) => ExploreState.fromJson(Map<String, dynamic>.from(item)))
        .where((state) => state.isActive)
        .toList();
  }

  // ==========================================================
  // Cities
  // ==========================================================

  Future<ExploreCitySearchResult> searchCities({
    String? search,
    String? countryId,
    String? stateId,
    int page = 1,
    int size = 20,
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

    return ExploreCitySearchResult.fromJson(data);
  }
}
