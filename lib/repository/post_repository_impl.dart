import 'dart:io';

import '../core/error/exceptions.dart';
import '../core/error/failures.dart';
import '../core/services/post_service.dart';
import '../data/models/post_model.dart';
import '../data/models/query_request.dart';
import '../data/models/rating_request.dart';
import '../data/models/replies_model.dart';
import '../data/models/sos_model.dart';
import 'post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostService _postService;

  PostRepositoryImpl(this._postService);

  @override
  Future<void> createPost(PostModel postData, File? file) async {
    try {
      await _postService.createPost(postData: postData, file: file);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error creating post: $e');
    }
  }

  @override
  Future<PostModel> getPost(String postId) async {
    try {
      return await _postService.getPost(postId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error getting post: $e');
    }
  }

  @override
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
      return await _postService.getPosts(
        city: city,
        state: state,
        country: country,
        neighbourhood: neighbourhood,
        zipcode: zipcode,
        severity: severity,
        userId: userId,
        timestampStart: timestampStart,
        timestampEnd: timestampEnd,
        limit: limit,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error fetching posts: $e');
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error deleting post: $e');
    }
  }

  @override
  Future<List<PostModel>> getPostsByProximity({
    required double lat,
    required double lng,
    int radius = 1000,
    String? severity,
    String? incidentType,
  }) async {
    try {
      return await _postService.getPostsByProximity(
        lat: lat,
        lng: lng,
        radius: radius,
        severity: severity,
        incidentType: incidentType,
      );
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error fetching nearby posts: $e');
    }
  }

  @override
  Future<void> ratePost(String postId, RatingRequest request) async {
    try {
      await _postService.ratePost(postId, request);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error rating post: $e');
    }
  }

  @override
  Future<void> createReply(RepliesModel replyData, File? file) async {
    try {
      await _postService.createReply(replyData: replyData, file: file);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error creating reply: $e');
    }
  }

  @override
  Future<List<RepliesModel>> getReplies(String postId) async {
    try {
      return await _postService.getReplies(postId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error fetching replies: $e');
    }
  }

  @override
  Future<void> rateReply(
    String postId,
    String replyId,
    RatingRequest request,
  ) async {
    try {
      await _postService.rateReply(postId, replyId, request);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error rating reply: $e');
    }
  }

  @override
  Future<void> createSos(SosModel sosData) async {
    try {
      await _postService.createSos(sosData);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error creating SOS: $e');
    }
  }

  @override
  Future<List<SosModel>> getAllSos() async {
    try {
      return await _postService.getAllSos();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error fetching SOS: $e');
    }
  }

  @override
  Future<List<SosModel>> getSosByReporter(String userId) async {
    try {
      return await _postService.getSosByReporter(userId);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error fetching SOS by reporter: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> queryVectors(QueryRequest request) async {
    try {
      return await _postService.queryVectors(request);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (e) {
      throw ServerFailure('Unexpected error querying vectors: $e');
    }
  }
}
