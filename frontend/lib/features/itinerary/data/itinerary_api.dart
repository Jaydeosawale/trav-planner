import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class ItineraryApi {
  ItineraryApi({Dio? client}) : _client = client ?? ApiClient.dio;
  final Dio _client;
  Future<List<Map<String, dynamic>>> load(String tripId) async =>
      ((await _client.get('/itinerary/trips/$tripId')).data['data']['days']
              as List)
          .map((day) => Map<String, dynamic>.from(day))
          .toList();
  Future<void> saveDay(
    String tripId,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    if (id == null) {
      await _client.post('/itinerary/trips/$tripId/days', data: data);
    } else {
      await _client.put('/itinerary/days/$id', data: data);
    }
  }

  Future<void> removeDay(String id) async {
    await _client.delete('/itinerary/days/$id');
  }

  Future<void> saveItem(
    String dayId,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    if (id == null) {
      await _client.post('/itinerary/days/$dayId/items', data: data);
    } else {
      await _client.put('/itinerary/items/$id', data: data);
    }
  }

  Future<void> removeItem(String id) async {
    await _client.delete('/itinerary/items/$id');
  }

  Future<void> order(String dayId, List<String> ids) async {
    await _client.put('/itinerary/days/$dayId/order', data: {'item_ids': ids});
  }
}
