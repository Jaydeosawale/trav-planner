import '../../../../core/network/api_client.dart';
import '../models/ai_response_model.dart';

class AIApi {
  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
  }) async {
    final response = await ApiClient.dio.post(
      '/ai/chat',
      data: {
      'message': message,
      'session_id':?sessionId,
      },
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid AI response.');
    }

    return AIResponseModel.fromJson(responseData);
  }
}
