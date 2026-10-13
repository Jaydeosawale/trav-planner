import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../destinations/data/place.dart';

class SavedPlacesApi {
  SavedPlacesApi({Dio? client}) : _client = client ?? ApiClient.dio;
  final Dio _client;

  Future<List<TravelPlace>> load() async {
    final response = await _client.get('/user/saved-places');
    final data = response.data['data'];
    if (data is! List) {
      throw const FormatException('Invalid saved places response');
    }
    return data
        .map((item) => TravelPlace.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> resolve(String id) async {
    await _client.post('/discovery/places/${Uri.encodeComponent(id)}/resolve');
  }

  Future<void> save(String id) async {
    await _client.post('/user/places/${Uri.encodeComponent(id)}/save');
  }

  Future<void> remove(String id) async {
    await _client.delete('/user/places/${Uri.encodeComponent(id)}/save');
  }
}
