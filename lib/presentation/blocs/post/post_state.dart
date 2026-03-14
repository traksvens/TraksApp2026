import 'package:equatable/equatable.dart';
import '../../../data/models/post_model.dart';

enum PostStatus { initial, loading, success, failure }

enum PostFormStatus { idle, submitting, success, failure }

class PostState extends Equatable {
  final PostStatus status;
  final PostFormStatus formStatus;
  final List<PostModel> posts;
  final String? errorMessage;
  final bool hasReachedMax;
  final Map<String, List<dynamic>> replies;

  const PostState({
    this.status = PostStatus.initial,
    this.formStatus = PostFormStatus.idle,
    this.posts = const <PostModel>[],
    this.errorMessage,
    this.hasReachedMax = false,
    this.replies = const {},
  });

  PostState copyWith({
    PostStatus? status,
    PostFormStatus? formStatus,
    List<PostModel>? posts,
    String? errorMessage,
    bool? hasReachedMax,
    Map<String, List<dynamic>>? replies,
  }) {
    return PostState(
      status: status ?? this.status,
      formStatus: formStatus ?? this.formStatus,
      posts: posts ?? this.posts,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      replies: replies ?? this.replies,
    );
  }

  @override
  List<Object?> get props => [
        status,
        formStatus,
        posts,
        errorMessage,
        hasReachedMax,
        replies,
      ];

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'formStatus': formStatus.index,
      'posts': posts.map((post) => post.toJson()).toList(),
      'errorMessage': errorMessage,
      'hasReachedMax': hasReachedMax,
      // Note: replies map complex serialization omitted for brevity if not strictly needed
      // or implement if offline replies are critical.
      // For now, focusing on main feed posts.
    };
  }

  factory PostState.fromJson(Map<String, dynamic> json) {
    return PostState(
      status: PostStatus.values[json['status'] as int? ?? 0],
      formStatus: PostFormStatus.values[json['formStatus'] as int? ?? 0],
      posts: (json['posts'] as List<dynamic>?)
              ?.map((e) => PostModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      errorMessage: json['errorMessage'] as String?,
      hasReachedMax: json['hasReachedMax'] as bool? ?? false,
    );
  }
}
