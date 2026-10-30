import '../../../../core/network/api_client.dart';
import '../models/ai_response_model.dart';

class AIApi {
  Future<Map<String, dynamic>> planUsage() async => Map<String, dynamic>.from(
    (await ApiClient.dio.get('/ai/plan-usage')).data,
  );

  Future<void> forgetSession(String id) async {
    await ApiClient.dio.delete('/ai/sessions/$id');
  }

  Future<List<Map<String, dynamic>>> sessions() async =>
      ((await ApiClient.dio.get('/ai/sessions')).data as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
  Future<Map<String, dynamic>> session(String id) async =>
      Map<String, dynamic>.from(
        (await ApiClient.dio.get('/ai/sessions/$id')).data,
      );
  Future<Map<String, dynamic>> saveBrief(
    Map<String, dynamic> data, {
    String? id,
  }) async => Map<String, dynamic>.from(
    (id == null
            ? await ApiClient.dio.post('/ai/sessions', data: data)
            : await ApiClient.dio.put('/ai/sessions/$id', data: data))
        .data,
  );

  Future<AIResponseModel> chat({
    required String message,
    String? sessionId,
  }) async {
    final response = await ApiClient.dio.post(
      '/ai/chat',
      data: {'message': message, 'session_id': ?sessionId},
    );

    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid AI response.');
    }

    return AIResponseModel.fromJson(responseData);
  }
}
