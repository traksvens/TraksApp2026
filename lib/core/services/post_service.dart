import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import '../../data/models/post_model.dart';
import '../../data/models/replies_model.dart';
import '../../data/models/sos_model.dart';
import '../../data/models/rating_request.dart';
import '../../data/models/query_request.dart';
import '../error/exceptions.dart';

class PostService {
  final Dio _dio;
  final String _baseUrl = dotenv.get('API_BASE_URL', fallback: '');

  PostService({Dio? dio}) : _dio = dio ?? Dio();

  // --- Posts ---

  Future<void> createPost({required PostModel postData, File? file}) async {
    // 1. File Size Check (10MB Limit)
    if (file != null) {
      final int sizeInBytes = await file.length();
      final double sizeInMb = sizeInBytes / (1024 * 1024);
      if (sizeInMb > 10) {
        throw ServerException(message: 'File size exceeds 10MB limit.');
      }
    }

    try {
      final String postDataJson = jsonEncode(postData.toJson());

      final FormData formData = FormData.fromMap({'post_data': postDataJson});

      if (file != null) {
        // Determine filename, default to something generic if path issues
        String fileName = file.path.split('/').last;
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await _dio.post(
        '$_baseUrl/posts/',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to create post: ${response.statusMessage}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data.toString() ?? e.message ?? 'Unknown Dio Error',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<PostModel> getPost(String postId) async {
    try {
      final response = await _dio.get('$_baseUrl/posts/$postId');
      if (response.statusCode == 200) {
        return PostModel.fromJson(response.data);
      } else {
        throw ServerException(
          message: 'Failed to get post',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data.toString() ?? e.message ?? 'Unknown Dio Error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<PostModel>> getPosts({
    String? city,
    String? state,
    String? country,
    String? neighbourhood,
    String? zipcode,
    String? severity,
    String? userId,
    String? timestampStart,
    String? timestampEnd,
    int limit = 100,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (country != null) 'country': country,
        if (neighbourhood != null) 'neighbourhood': neighbourhood,
        if (zipcode != null) 'zipcode': zipcode,
        if (severity != null) 'severity': severity,
        if (userId != null) 'user_id': userId,
        if (timestampStart != null) 'timestamp_start': timestampStart,
        if (timestampEnd != null) 'timestamp_end': timestampEnd,
        'limit': limit,
      };

      final response = await _dio.get(
        '$_baseUrl/posts',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Assuming response.data is a List
        final List<dynamic> data = response.data;
        return data.map((e) => PostModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch posts',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Unknown Dio Error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final response = await _dio.delete('$_baseUrl/posts/$postId');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          message: 'Failed to delete post',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Unknown Dio Error',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<PostModel>> getPostsByProximity({
    required double lat,
    required double lng,
    int radius = 1000,
  }) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/locations/proximity/',
        queryParameters: {
          'lat': lat.toString(),
          'long': lng.toString(),
          'radius': radius,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      throw ServerException(
        message: 'Failed to fetch nearby posts',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error fetching nearby posts',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> ratePost(String postId, RatingRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/posts/$postId/rate',
        data: request.toJson(),
      );
      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to rate post',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error rating post',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // --- Replies ---

  Future<void> createReply({
    required RepliesModel replyData,
    File? file,
  }) async {
    try {
      final String replyDataJson = jsonEncode(replyData.toJson());

      final FormData formData = FormData.fromMap({'reply_data': replyDataJson});

      if (file != null) {
        // Check size again if needed, or assume caller checked
        final int sizeInBytes = await file.length();
        final double sizeInMb = sizeInBytes / (1024 * 1024);
        if (sizeInMb > 10) {
          throw ServerException(message: 'File size exceeds 10MB limit.');
        }

        String fileName = file.path.split('/').last;
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await _dio.post(
        '$_baseUrl/replies/',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to create reply',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data.toString() ?? e.message ?? 'Error creating reply',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<RepliesModel>> getReplies(String postId) async {
    try {
      final response = await _dio.get('$_baseUrl/posts/$postId/replies');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => RepliesModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch replies',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error getting replies',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> rateReply(
    String postId,
    String replyId,
    RatingRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/posts/$postId/replies/$replyId/rate',
        data: request.toJson(),
      );
      if (response.statusCode != 200) {
        throw ServerException(
          message: 'Failed to rate reply',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error rating reply',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // --- SOS ---

  Future<void> createSos(SosModel sosData) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/sos/',
        data: sosData.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          message: 'Failed to create SOS',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message:
            e.response?.data.toString() ?? e.message ?? 'Error creating SOS',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<SosModel>> getAllSos() async {
    try {
      final response = await _dio.get('$_baseUrl/sos/');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => SosModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch SOS',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error fetching SOS',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<SosModel>> getSosByReporter(String userId) async {
    try {
      final response = await _dio.get('$_baseUrl/users/$userId/sos');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => SosModel.fromJson(e)).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch SOS by reporter',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error fetching SOS by reporter',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // --- Search ---

  Future<Map<String, dynamic>> queryVectors(QueryRequest request) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/vectors/query',
        data: request.toJson(),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
        // Expected: { "matches": [...], "post_ids": [...] }
      } else {
        throw ServerException(
          message: 'Failed to query vectors',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Error querying vectors',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
