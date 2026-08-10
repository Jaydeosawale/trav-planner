import '../../../../core/network/api_client.dart';
import '../models/banner_model.dart';

class BannerApi {
  Future<List<BannerModel>> getBanners() async {
    final response = await ApiClient.dio.get(
      '/banner/',
    );

    final data = response.data;

    if (data is! List) {
      throw Exception(
        'Invalid banner response from server.',
      );
    }

    return data
        .map(
          (item) => BannerModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .where(
          (banner) =>
              banner.isActive &&
              banner.imageUrl.isNotEmpty,
        )
        .toList()
      ..sort(
        (a, b) => a.displayOrder.compareTo(
          b.displayOrder,
        ),
      );
  }
}
