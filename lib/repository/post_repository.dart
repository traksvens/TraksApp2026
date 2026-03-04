import 'dart:io';

import '../data/models/post_model.dart';
import '../data/models/replies_model.dart';
import '../data/models/sos_model.dart';
import '../data/models/rating_request.dart';
import '../data/models/query_request.dart';

abstract class PostRepository {
  // Posts
  Future<void> createPost(PostModel postData, File? file);
  Future<PostModel> getPost(String postId);
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
  });
  Future<void> deletePost(String postId);
  Future<void> ratePost(String postId, RatingRequest request);

  // Replies
  Future<void> createReply(RepliesModel replyData, File? file);
  Future<List<RepliesModel>> getReplies(String postId);
  Future<void> rateReply(String postId, String replyId, RatingRequest request);

  // SOS
  Future<void> createSos(SosModel sosData);
  Future<List<SosModel>> getAllSos();
  Future<List<SosModel>> getSosByReporter(String userId);

  // Vectors
  Future<Map<String, dynamic>> queryVectors(QueryRequest request);
}
