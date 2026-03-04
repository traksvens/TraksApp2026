import 'package:dio/dio.dart';
import '../constants/api_keys.dart';

class PlacesService {
  final Dio _dio;
  final String _v1BaseUrl = 'https://places.googleapis.com/v1/places';

  PlacesService(this._dio);

  Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
    String query,
  ) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.post(
        '$_v1BaseUrl:autocomplete',
        data: {
          'input': query,
          // You can add more parameters here like locationBias if needed
        },
        options: Options(
          headers: {
            'X-Goog-Api-Key': ApiKeys.googleMapsApiKey,
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data != null && data['suggestions'] != null) {
        return List<Map<String, dynamic>>.from(
          (data['suggestions'] as List).map((s) => s['placePrediction']),
        );
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, double>?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        '$_v1BaseUrl/$placeId',
        options: Options(
          headers: {
            'X-Goog-Api-Key': ApiKeys.googleMapsApiKey,
            'X-Goog-FieldMask': 'location',
          },
        ),
      );

      final data = response.data;
      if (data != null && data['location'] != null) {
        return {
          'lat': (data['location']['latitude'] as num).toDouble(),
          'lng': (data['location']['longitude'] as num).toDouble(),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
