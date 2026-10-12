import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class TravelPreferencesApi {
  TravelPreferencesApi({Dio? client}) : _client = client ?? ApiClient.dio;
  final Dio _client;

  Future<Map<String, dynamic>> load() async {
    final response = await _client.get('/user/profile');
    final data = response.data['data'];
    return data == null ? {} : Map<String, dynamic>.from(data);
  }

  Future<void> save(Map<String, dynamic> preferences) async {
    await _client.put('/user/profile', data: preferences);
  }
}
