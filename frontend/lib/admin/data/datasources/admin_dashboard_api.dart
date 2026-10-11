import '../../../../core/network/api_client.dart';
import '../models/admin_dashboard_model.dart';

class AdminDashboardApi {
  Future<AdminDashboardModel> getDashboard() async {
    final response = await ApiClient.dio.get('/admin/dashboard');

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard response.');
    }

    if (responseData['success'] != true) {
      throw Exception(
        responseData['message'] ??
            responseData['error'] ??
            'Failed to load dashboard.',
      );
    }

    final data = responseData['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid dashboard data.');
    }

    return AdminDashboardModel.fromJson(data);
  }
}
