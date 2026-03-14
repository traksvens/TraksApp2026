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

  Future<Map<String, dynamic>?> resolveTextLocation(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    try {
      final response = await _dio.post(
        '$_v1BaseUrl:searchText',
        data: {'textQuery': trimmed, 'maxResultCount': 1},
        options: Options(
          headers: {
            'X-Goog-Api-Key': ApiKeys.googleMapsApiKey,
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,places.location',
            'Content-Type': 'application/json',
          },
        ),
      );

      final places = response.data?['places'] as List<dynamic>? ?? const [];
      if (places.isEmpty) return null;

      final place = Map<String, dynamic>.from(places.first as Map);
      final location = place['location'] as Map<String, dynamic>?;
      final lat = (location?['latitude'] as num?)?.toDouble();
      final lng = (location?['longitude'] as num?)?.toDouble();

      if (lat == null || lng == null) return null;

      final displayName = place['displayName'] as Map<String, dynamic>?;
      final label = displayName?['text'] as String? ??
          place['formattedAddress'] as String? ??
          trimmed;

      return {'lat': lat, 'lng': lng, 'label': label};
    } catch (e) {
      return null;
    }
  }

  Future<String?> reverseGeocodeLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await _dio.get(
        'https://geocode.googleapis.com/v4beta/geocode/location',
        queryParameters: {'location.latitude': lat, 'location.longitude': lng},
        options: Options(
          headers: {
            'X-Goog-Api-Key': ApiKeys.googleMapsApiKey,
            'X-Goog-FieldMask': 'results.formattedAddress',
          },
        ),
      );

      final results = response.data?['results'] as List<dynamic>? ?? const [];
      if (results.isEmpty) return null;

      final first = results.first as Map<String, dynamic>;
      return first['formattedAddress'] as String?;
    } catch (e) {
      return null;
    }
  }
}
