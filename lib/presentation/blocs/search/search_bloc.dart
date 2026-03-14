import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../../repository/post_repository.dart';
import '../../../data/models/query_request.dart';
import '../../../data/models/post_model.dart';

// Models
class SearchFilters extends Equatable {
  final String? city;
  final String? state;
  final String? country;
  final String? neighbourhood;
  final String? zipcode;
  final String? severity;
  final String? incidentType;
  final String? userId; // mapped to user_id in API
  final DateTime? timestampStart;
  final DateTime? timestampEnd;

  const SearchFilters({
    this.city,
    this.state,
    this.country,
    this.neighbourhood,
    this.zipcode,
    this.severity,
    this.incidentType,
    this.userId,
    this.timestampStart,
    this.timestampEnd,
  });

  bool get hasFilters =>
      city != null ||
      state != null ||
      country != null ||
      neighbourhood != null ||
      zipcode != null ||
      severity != null ||
      incidentType != null ||
      userId != null ||
      timestampStart != null ||
      timestampEnd != null;

  @override
  List<Object?> get props => [
        city,
        state,
        country,
        neighbourhood,
        zipcode,
        severity,
        incidentType,
        userId,
        timestampStart,
        timestampEnd,
      ];
}

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  final String query;
  const SearchQueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ApplySearchFilters extends SearchEvent {
  final SearchFilters filters;
  const ApplySearchFilters(this.filters);
  @override
  List<Object?> get props => [filters];
}

class LoadRecentPosts extends SearchEvent {}

// State
enum SearchStatus { initial, loading, loaded, failure }

class SearchState extends Equatable {
  final SearchStatus status;
  final List<dynamic> results; // Can be List<PostModel> or List<Map>
  final List<String> postIds;
  final String? errorMessage;
  final SearchFilters filters;
  final String query;

  const SearchState({
    this.status = SearchStatus.initial,
    this.results = const [],
    this.postIds = const [],
    this.errorMessage,
    this.filters = const SearchFilters(),
    this.query = '',
  });

  SearchState copyWith({
    SearchStatus? status,
    List<dynamic>? results,
    List<String>? postIds,
    String? errorMessage,
    SearchFilters? filters,
    String? query,
  }) {
    return SearchState(
      status: status ?? this.status,
      results: results ?? this.results,
      postIds: postIds ?? this.postIds,
      errorMessage: errorMessage ?? this.errorMessage,
      filters: filters ?? this.filters,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [
        status,
        results,
        postIds,
        errorMessage,
        filters,
        query,
      ];
}

// Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final PostRepository repository;

  SearchBloc({required this.repository}) : super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged, transformer: _debounce());
    on<ApplySearchFilters>(_onFiltersChanged);
    on<LoadRecentPosts>(_onLoadRecentPosts);

    // Initial load
    add(LoadRecentPosts());
  }

  EventTransformer<T> _debounce<T>() {
    return (events, mapper) =>
        events.debounceTime(const Duration(milliseconds: 500)).flatMap(mapper);
  }

  Future<void> _onLoadRecentPosts(
    LoadRecentPosts event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(status: SearchStatus.loading));
    try {
      final posts = await repository.getPosts(limit: 5);
      emit(state.copyWith(status: SearchStatus.loaded, results: posts));
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final newQuery = event.query;
    if (newQuery.isEmpty && !state.filters.hasFilters) {
      add(LoadRecentPosts());
      emit(state.copyWith(query: newQuery));
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading, query: newQuery));

    try {
      await _performSearch(emit, newQuery, state.filters);
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onFiltersChanged(
    ApplySearchFilters event,
    Emitter<SearchState> emit,
  ) async {
    emit(state.copyWith(status: SearchStatus.loading, filters: event.filters));
    try {
      await _performSearch(emit, state.query, event.filters);
    } catch (e) {
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _performSearch(
    Emitter<SearchState> emit,
    String query,
    SearchFilters filters,
  ) async {
    // Construct filters map for metadata
    final Map<String, dynamic> filterMap = {};
    if (filters.city != null) filterMap['city'] = filters.city;
    if (filters.state != null) filterMap['state'] = filters.state;
    if (filters.country != null) filterMap['country'] = filters.country;
    if (filters.neighbourhood != null) {
      filterMap['neighbourhood'] = filters.neighbourhood;
    }
    if (filters.zipcode != null) filterMap['zipcode'] = filters.zipcode;
    if (filters.severity != null) filterMap['severity'] = filters.severity;
    if (filters.incidentType != null) {
      filterMap['incidentType'] = filters.incidentType;
    }
    if (filters.userId != null) filterMap['user_id'] = filters.userId;

    // Use vectors/query for everything
    final result = await repository.queryVectors(
      QueryRequest(
        text: query.isEmpty ? " " : query,
        filters: filterMap.isNotEmpty ? filterMap : null,
        timestampStart: filters.timestampStart?.toIso8601String(),
        timestampEnd: filters.timestampEnd?.toIso8601String(),
      ),
    );

    final matches = result['matches'] as List<dynamic>? ?? [];
    List<PostModel> posts = [];

    try {
      posts = matches.map((m) {
        if (m is Map<String, dynamic>) {
          final metadata = m['metadata'] != null
              ? Map<String, dynamic>.from(m['metadata'] as Map)
              : m;

          if (metadata['id'] == null && m['id'] != null) {
            metadata['id'] = m['id'];
          }

          return PostModel.fromJson(metadata);
        }
        throw Exception("Invalid match format");
      }).toList();
    } catch (e) {
      // Fallback: results will be handled as raw matches if mapping fails
    }

    final postIds = (result['post_ids'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    emit(
      state.copyWith(
        status: SearchStatus.loaded,
        results: posts.isNotEmpty ? posts : matches,
        postIds: postIds,
      ),
    );
  }
}
