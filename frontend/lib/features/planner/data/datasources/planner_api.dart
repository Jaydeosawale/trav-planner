import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../models/planner_request.dart';
import '../models/planner_response.dart';

class PlannerApi {
  Future<PlannerResponse> createPlan(
    PlannerRequest request,
  ) async {
    final response = await ApiClient.dio.post(
      "/planner/",
      data: request.toJson(),
    );

    final apiResponse =
        ApiResponse<PlannerResponse>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => PlannerResponse.fromJson(
        data as Map<String, dynamic>,
      ),
    );

    if (!apiResponse.success ||
        apiResponse.data == null) {
      throw Exception(
        apiResponse.message ??
            "Failed to create planner.",
      );
    }

    return apiResponse.data!;
  }
}