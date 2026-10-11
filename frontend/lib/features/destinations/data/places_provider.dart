import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'place.dart';

final cityPlacesProvider = FutureProvider.autoDispose
    .family<List<TravelPlace>, String>((ref, cityId) async {
      final response = await ApiClient.dio.get(
        '/places/search',
        queryParameters: {'city_id': cityId, 'size': 100},
        // Allow the free backend time to wake up without changing every API request.
        options: Options(receiveTimeout: const Duration(seconds: 75)),
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final places = (data['items'] as List)
          .whereType<Map>()
          .where((item) => item['is_active'] != false)
          .map((item) => TravelPlace.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      places.sort((a, b) {
        final featured = (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
        return featured != 0 ? featured : a.name.compareTo(b.name);
      });
      return places;
    });
