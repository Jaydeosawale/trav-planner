import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/destination_model.dart';

class DestinationApi {
  Future<List<DestinationModel>> getDestinations() async {
    final response = await ApiClient.dio.get(
      "/destinations/",
    );

    final apiResponse =
        ApiResponse<List<DestinationModel>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) {
        final items = data as List<dynamic>;

        return items
            .map(
              (item) => DestinationModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      },
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(
        apiResponse.message ??
            "Failed to load destinations.",
      );
    }

    return apiResponse.data!;
  }
}