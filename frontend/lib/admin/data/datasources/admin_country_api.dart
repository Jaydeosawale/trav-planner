import '../../../../core/network/api_client.dart';
import '../models/admin_country_model.dart';

class AdminCountryApi {
  // ==========================================================
  // Get active countries
  //
  // Used by Places / Cities / other forms.
  // ==========================================================

  Future<List<AdminCountryModel>> getActiveCountries() async {
    final response = await ApiClient.dio.get('/countries/active');

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid country response from server.');
    }

    final items = data['data'];

    if (items is! List) {
      throw Exception('Invalid country data from server.');
    }

    return items
        .map(
          (item) => AdminCountryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // ==========================================================
  // Admin - Get all countries
  // ==========================================================

  Future<List<AdminCountryModel>> getAllCountries() async {
    final response = await ApiClient.dio.get('/admin/countries/');

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid admin country response from server.');
    }

    return data
        .map(
          (item) => AdminCountryModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  // ==========================================================
  // Admin - Get country
  // ==========================================================

  Future<AdminCountryModel> getCountry(String countryId) async {
    final response = await ApiClient.dio.get('/admin/countries/$countryId');

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid country response from server.');
    }

    return AdminCountryModel.fromJson(data);
  }

  // ==========================================================
  // Admin - Update country status
  // ==========================================================

  Future<AdminCountryModel> updateCountryStatus({
    required String countryId,
    required bool isActive,
  }) async {
    final response = await ApiClient.dio.patch(
      '/admin/countries/$countryId',
      data: {'is_active': isActive},
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid country update response from server.');
    }

    return AdminCountryModel.fromJson(data);
  }
}
