import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class TripsApi {
  TripsApi({Dio? client}) : _client = client ?? ApiClient.dio;
  final Dio _client;
  Map<String, String>? _countryNames;
  Future<Map<String, dynamic>> list(int page) async =>
      Map<String, dynamic>.from(
        (await _client.get(
          '/trips/',
          queryParameters: {'page': page, 'size': 20},
        )).data['data'],
      );
  Future<Map<String, dynamic>> get(String id) async =>
      Map<String, dynamic>.from((await _client.get('/trips/$id')).data['data']);
  Future<Map<String, dynamic>> save(
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final response = id == null
        ? await _client.post('/trips/', data: payload)
        : await _client.put('/trips/$id', data: payload);
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<void> remove(String id) async {
    await _client.delete('/trips/$id');
  }

  Future<List<Map<String, dynamic>>> cities(String query) async {
    final response = await _client.get(
      '/cities/search',
      queryParameters: {'search': query, 'size': 20},
    );
    if (_countryNames == null) {
      try {
        final countries =
            (await _client.get('/countries/active')).data['data'] as List;
        _countryNames = {
          for (final country in countries)
            country['id'].toString(): country['name'].toString(),
        };
      } catch (_) {
        /* City selection remains available when country labels cannot load. */
      }
    }
    return (response.data['data']['items'] as List)
        .map((city) => Map<String, dynamic>.from(city))
        .map((city) => {...city, 'country': _countryNames?[city['country_id']]})
        .toList();
  }
}
