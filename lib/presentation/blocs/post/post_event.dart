import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../data/models/post_model.dart';
import '../../../data/models/rating_request.dart';

abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

class FetchPosts extends PostEvent {
  final String? city;
  final String? userId;
  final String? incidentType;

  const FetchPosts({this.city, this.userId, this.incidentType});

  @override
  List<Object?> get props => [city, userId, incidentType];
}

class CreatePost extends PostEvent {
  final PostModel post;
  final File? file;

  const CreatePost({required this.post, this.file});

  @override
  List<Object?> get props => [post, file];
}

class RatePostEvent extends PostEvent {
  final String postId;
  final RatingRequest request;

  const RatePostEvent({required this.postId, required this.request});

  @override
  List<Object?> get props => [postId, request];
}

class FetchReplies extends PostEvent {
  final String postId;

  const FetchReplies(this.postId);

  @override
  List<Object?> get props => [postId];
}

class CreateReply extends PostEvent {
  final String postId;
  final String userId;
  final String content;

  const CreateReply({
    required this.postId,
    required this.userId,
    required this.content,
  });

  @override
  List<Object?> get props => [postId, userId, content];
}
