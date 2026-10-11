import '../../../../core/network/api_client.dart';
import '../models/admin_category_model.dart';

class AdminCategoryApi {
  // ==========================================================
  // Get active categories
  // ==========================================================

  Future<List<AdminCategoryModel>> getActiveCategories() async {
    final response = await ApiClient.dio.get('/categories/active');

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid category response from server.');
    }

    final data = responseData['data'];

    if (data is! List) {
      throw Exception('Invalid category data from server.');
    }

    return data
        .map(
          (item) => AdminCategoryModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // ==========================================================
  // Get root categories
  // ==========================================================

  Future<List<AdminCategoryModel>> getRootCategories() async {
    final response = await ApiClient.dio.get('/categories/roots');

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid category response from server.');
    }

    final data = responseData['data'];

    if (data is! List) {
      throw Exception('Invalid category data from server.');
    }

    return data
        .map(
          (item) => AdminCategoryModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // ==========================================================
  // Get child categories
  // ==========================================================

  Future<List<AdminCategoryModel>> getChildren(String parentId) async {
    final response = await ApiClient.dio.get('/categories/$parentId/children');

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid category response from server.');
    }

    final data = responseData['data'];

    if (data is! List) {
      throw Exception('Invalid category data from server.');
    }

    return data
        .map(
          (item) => AdminCategoryModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
