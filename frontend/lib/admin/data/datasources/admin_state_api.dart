import '../../../../core/network/api_client.dart';
import '../models/admin_state_model.dart';

class AdminStateApi {
  // ==========================================================
  // Get active states for a country
  // ==========================================================

  Future<List<AdminStateModel>> getStatesByCountry(String countryId) async {
    final response = await ApiClient.dio.get('/states/country/$countryId');

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid state response from server.');
    }

    final items = data['data'];

    if (items is! List) {
      throw Exception('Invalid state data from server.');
    }

    return items
        .map((item) => AdminStateModel.fromJson(item as Map<String, dynamic>))
        .where((state) => state.isActive)
        .toList();
  }
}
