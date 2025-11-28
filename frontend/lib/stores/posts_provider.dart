import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/stores/filter_store.dart';
import 'package:http/http.dart' as http;

// =====================================================================
//                         POSTS STATE
// =====================================================================

class PostsState {
  final List<dynamic> posts;
  final int currentPage;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  const PostsState({
    this.posts = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  PostsState copyWith({
    List<dynamic>? posts,
    int? currentPage,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
    );
  }
}

// =====================================================================
//                         POSTS NOTIFIER
// =====================================================================

class PostsNotifier extends Notifier<PostsState> {
  @override
  PostsState build() => const PostsState();

  String _buildUrl(int page) {
    final filters = ref.read(filterStoreProvider);
    final params = <String, String>{
      'page': page.toString(),
      'limit': '10',
    };

    if (filters.type != null) params['type'] = filters.type!;
    if (filters.categories.isNotEmpty) params['categories'] = filters.categories.join(',');
    if (filters.highReward) params['highReward'] = 'true';
    if (filters.nearMe && filters.location != null) {
      params['near_me'] = 'true';
      params['lat'] = filters.location!.lat.toString();
      params['lng'] = filters.location!.lng.toString();
    }

    final uri = Uri.parse("${ApiConstants.baseUrl}/posts");
    return uri.replace(queryParameters: params).toString();
  }

  Future<void> fetchPosts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final url = _buildUrl(1);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        state = PostsState(
          posts: data['posts'] ?? [],
          currentPage: 1,
          hasMore: data['pagination']?['hasMore'] ?? false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load posts');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final url = _buildUrl(nextPage);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final newPosts = List.from(state.posts)..addAll(data['posts'] ?? []);
        
        state = state.copyWith(
          posts: newPosts,
          currentPage: nextPage,
          hasMore: data['pagination']?['hasMore'] ?? false,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final postsProvider = NotifierProvider<PostsNotifier, PostsState>(() {
  return PostsNotifier();
});
