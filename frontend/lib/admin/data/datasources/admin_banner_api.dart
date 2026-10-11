import '../../../../core/network/api_client.dart';
import '../models/admin_banner_model.dart';

class AdminBannerApi {
  // ==========================================================
  // Get all banners for Admin CMS
  // ==========================================================

  Future<List<AdminBannerModel>> getAllBanners() async {
    final response = await ApiClient.dio.get('/banner/admin/all');

    final data = response.data;

    if (data is! List) {
      throw Exception('Invalid banner response from server.');
    }

    return data
        .map((item) => AdminBannerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ==========================================================
  // Get banner by ID
  // ==========================================================

  Future<AdminBannerModel> getBanner(String id) async {
    final response = await ApiClient.dio.get('/banner/$id');

    return AdminBannerModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ==========================================================
  // Create banner
  // ==========================================================

  Future<AdminBannerModel> createBanner({
    required String title,
    String? subtitle,
    required String imageUrl,
    String? redirectUrl,
    int displayOrder = 0,
    bool isActive = true,
    DateTime? startsAt,
    DateTime? endsAt,
    String? campaignName,
    int priority = 0,
  }) async {
    final response = await ApiClient.dio.post(
      '/banner/',
      data: {
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'redirect_url': redirectUrl,
        'display_order': displayOrder,
        'is_active': isActive,
        'starts_at': startsAt?.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'campaign_name': campaignName,
        'priority': priority,
      },
    );

    return AdminBannerModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ==========================================================
  // Update banner
  // ==========================================================

  Future<AdminBannerModel> updateBanner({
    required String id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? redirectUrl,
    int? displayOrder,
    bool? isActive,
    DateTime? startsAt,
    DateTime? endsAt,
    String? campaignName,
    int? priority,
  }) async {
    final data = <String, dynamic>{};

    if (title != null) {
      data['title'] = title;
    }

    if (subtitle != null) {
      data['subtitle'] = subtitle;
    }

    if (imageUrl != null) {
      data['image_url'] = imageUrl;
    }

    if (redirectUrl != null) {
      data['redirect_url'] = redirectUrl;
    }

    if (displayOrder != null) {
      data['display_order'] = displayOrder;
    }

    if (isActive != null) {
      data['is_active'] = isActive;
    }

    if (startsAt != null) {
      data['starts_at'] = startsAt.toIso8601String();
    }

    if (endsAt != null) {
      data['ends_at'] = endsAt.toIso8601String();
    }

    if (campaignName != null) {
      data['campaign_name'] = campaignName;
    }

    if (priority != null) {
      data['priority'] = priority;
    }

    final response = await ApiClient.dio.put('/banner/$id', data: data);

    return AdminBannerModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ==========================================================
  // Delete banner
  // ==========================================================

  Future<void> deleteBanner(String id) async {
    await ApiClient.dio.delete('/banner/$id');
  }
}
