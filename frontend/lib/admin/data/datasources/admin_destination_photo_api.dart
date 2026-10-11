import '../../../../core/network/api_client.dart';
import '../models/admin_destination_photo_model.dart';

class AdminDestinationPhotoApi {
  // ==========================================================
  // Get admin gallery
  // ==========================================================

  Future<List<AdminDestinationPhotoModel>> getPhotos(
    String destinationId,
  ) async {
    final response = await ApiClient.dio.get(
      '/destination-photos/destination/$destinationId',
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid destination photo response from server.');
    }

    final items = data['data'];

    if (items is! List) {
      throw Exception('Invalid destination photo data from server.');
    }

    return items
        .map(
          (item) =>
              AdminDestinationPhotoModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  // ==========================================================
  // Add photo
  // ==========================================================

  Future<AdminDestinationPhotoModel> addPhoto({
    required String destinationId,
    required String imageUrl,
    String? caption,
    int displayOrder = 0,
    bool isCover = false,
    bool isActive = true,
  }) async {
    final response = await ApiClient.dio.post(
      '/destination-photos/destination/$destinationId',
      data: {
        'image_url': imageUrl,
        'caption': caption,
        'display_order': displayOrder,
        'is_cover': isCover,
        'is_active': isActive,
      },
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid destination photo response from server.');
    }

    return AdminDestinationPhotoModel.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // Update photo
  // ==========================================================

  Future<AdminDestinationPhotoModel> updatePhoto({
    required String photoId,
    String? imageUrl,
    String? caption,
    int? displayOrder,
    bool? isCover,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};

    if (imageUrl != null) {
      payload['image_url'] = imageUrl;
    }

    if (caption != null) {
      payload['caption'] = caption;
    }

    if (displayOrder != null) {
      payload['display_order'] = displayOrder;
    }

    if (isCover != null) {
      payload['is_cover'] = isCover;
    }

    if (isActive != null) {
      payload['is_active'] = isActive;
    }

    final response = await ApiClient.dio.patch(
      '/destination-photos/$photoId',
      data: payload,
    );

    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid destination photo response from server.');
    }

    return AdminDestinationPhotoModel.fromJson(
      data['data'] as Map<String, dynamic>,
    );
  }

  // ==========================================================
  // Delete photo
  // ==========================================================

  Future<void> deletePhoto(String photoId) async {
    await ApiClient.dio.delete('/destination-photos/$photoId');
  }
}
