import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../../data/models/replies_model.dart';
import '../../../repository/post_repository.dart';
import '../../../core/error/failures.dart';
import '../../../data/models/post_model.dart';
import 'post_event.dart';
import 'post_state.dart';

class PostBloc extends HydratedBloc<PostEvent, PostState> {
  final PostRepository repository;

  PostBloc({required this.repository}) : super(const PostState()) {
    on<FetchPosts>(_onFetchPosts);
    on<CreatePost>(_onCreatePost);
    on<RatePostEvent>(_onRatePost);
    on<FetchReplies>(_onFetchReplies);
    on<CreateReply>(_onCreateReply);
  }

  @override
  PostState? fromJson(Map<String, dynamic> json) {
    return PostState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(PostState state) {
    return state.toJson();
  }

  Future<void> _onFetchReplies(
    FetchReplies event,
    Emitter<PostState> emit,
  ) async {
    try {
      final replies = await repository.getReplies(event.postId);
      // Sort replies by timestamp descending
      replies.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final updatedReplies = Map<String, List<RepliesModel>>.from(
        state.replies,
      );
      updatedReplies[event.postId] = replies;
      emit(state.copyWith(replies: updatedReplies));
    } catch (e) {
      // Handle error silently or via specific state if needed
    }
  }

  Future<void> _onCreateReply(
    CreateReply event,
    Emitter<PostState> emit,
  ) async {
    try {
      await repository.createReply(
        RepliesModel(
          id: '', // Server will assign ID
          postId: event.postId,
          userId: event.userId,
          content: event.content,
          timestamp: DateTime.now().toIso8601String(),
          fileUrl: null,
        ),
        null,
      );
      add(FetchReplies(event.postId));
      // Optionally update post reply count locally
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to reply: $e'));
    }
  }

  Future<void> _onFetchPosts(FetchPosts event, Emitter<PostState> emit) async {
    // Only set loading if it's the first load AND we have no cached posts
    if (state.posts.isEmpty) {
      emit(state.copyWith(status: PostStatus.loading));
    }

    try {
      final posts = await repository.getPosts(
        city: event.city,
        userId: event.userId,
        // TODO: Handle more filters if needed
      );
      // Sort posts by timestamp descending (most recent first)
      posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      emit(state.copyWith(status: PostStatus.success, posts: posts));
    } on Failure catch (e) {
      emit(state.copyWith(status: PostStatus.failure, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(status: PostStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onCreatePost(CreatePost event, Emitter<PostState> emit) async {
    emit(state.copyWith(formStatus: PostFormStatus.submitting));
    try {
      await repository.createPost(event.post, event.file);

      // PERF: Optimistic update - add the post immediately to the top of the list
      // with a temporary ID. This provides instant feedback to the user.
      final optimisticPost = event.post.copyWith(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      );
      final updatedPosts = [optimisticPost, ...state.posts];

      emit(
        state.copyWith(formStatus: PostFormStatus.success, posts: updatedPosts),
      );

      // Background fetch to reconcile with server state (gets real ID and any server-side data)
      // This runs after success so the UI already shows the post
      add(const FetchPosts());
    } on Failure catch (e) {
      emit(
        state.copyWith(
          formStatus: PostFormStatus.failure,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          formStatus: PostFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onRatePost(RatePostEvent event, Emitter<PostState> emit) async {
    final currentPosts = List<PostModel>.from(state.posts);
    final index = currentPosts.indexWhere((p) => p.id == event.postId);

    if (index == -1) return;

    final post = currentPosts[index];
    final currentRating = post.ratedBy[event.request.userId];
    final newRating = event.request.rating;

    // Calculate optimistic deltas
    bool isRemoving = currentRating == newRating;
    int confirmDelta = 0;
    int refuteDelta = 0;

    if (isRemoving) {
      if (currentRating == 'confirm') confirmDelta = -1;
      if (currentRating == 'refute') refuteDelta = -1;
    } else {
      if (newRating == 'confirm') {
        confirmDelta = 1;
        if (currentRating == 'refute') refuteDelta = -1;
      } else if (newRating == 'refute') {
        refuteDelta = 1;
        if (currentRating == 'confirm') confirmDelta = -1;
      }
    }

    final Map<String, String> updatedRatedBy = Map<String, String>.from(
      post.ratedBy,
    );
    if (isRemoving) {
      updatedRatedBy.remove(event.request.userId);
    } else {
      updatedRatedBy[event.request.userId] = newRating;
    }

    final optimisticPost = post.copyWith(
      confirmCount: (post.confirmCount + confirmDelta).clamp(0, 999999),
      refuteCount: (post.refuteCount + refuteDelta).clamp(0, 999999),
      ratedBy: updatedRatedBy,
    );

    currentPosts[index] = optimisticPost;

    // Emit optimistic state
    emit(state.copyWith(posts: currentPosts, errorMessage: null));

    try {
      await repository.ratePost(event.postId, event.request);

      // Fetch the updated post to get accurate counts from server
      final updatedPost = await repository.getPost(event.postId);

      final newPosts = List<PostModel>.from(state.posts);
      final newIndex = newPosts.indexWhere((p) => p.id == event.postId);

      if (newIndex != -1) {
        newPosts[newIndex] = updatedPost;
        emit(state.copyWith(posts: newPosts));
      }
    } catch (e) {
      // Rollback on failure
      final rollbackPosts = List<PostModel>.from(state.posts);
      final rollbackIndex = rollbackPosts.indexWhere(
        (p) => p.id == event.postId,
      );
      if (rollbackIndex != -1) {
        rollbackPosts[rollbackIndex] = post; // Revert to original post
        emit(
          state.copyWith(
            posts: rollbackPosts,
            errorMessage: 'Failed to update vote: ${e.toString()}',
          ),
        );
      } else {
        emit(
          state.copyWith(
            errorMessage: 'Failed to update vote: ${e.toString()}',
          ),
        );
      }
    }
  }
}
