import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LikeState {
  final Set<String> likedComments; // just tracks which ones are liked
  final Map<String, int> likeCounts; // tracks updated like counts

  LikeState({
    required this.likedComments,
    required this.likeCounts,
  });
}

class LikesNotifier extends StateNotifier<LikeState> {
  LikesNotifier()
      : super(LikeState(
          likedComments: {},
          likeCounts: {},
        ));

  Future<void> toggleLike(String commentId, int currentLikes) async {
    final isLiked = state.likedComments.contains(commentId);

    // Calculate new like count
    final newLikeCount = isLiked ? currentLikes - 1 : currentLikes + 1;

    // Store old state for rollback
    final oldLikedComments = Set<String>.from(state.likedComments);
    final oldLikeCounts = Map<String, int>.from(state.likeCounts);

    // Optimistic update - update state
    if (isLiked) {
      state.likedComments.remove(commentId);
    } else {
      state.likedComments.add(commentId);
    }
    
    state.likeCounts[commentId] = newLikeCount;

    state = LikeState(
      likedComments: state.likedComments,
      likeCounts: state.likeCounts,
    );

    // API call
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      // Simulate API call - will replace with real endpoint later
    } catch (e) {
      // Rollback on failure
      state = LikeState(
        likedComments: oldLikedComments,
        likeCounts: oldLikeCounts,
      );
    }
  }

  bool isCommentLiked(String commentId) {
    return state.likedComments.contains(commentId);
  }

  int getLikeCount(String commentId, int defaultCount) {
    return state.likeCounts[commentId] ?? defaultCount;
  }
}

final likesProvider =
    StateNotifierProvider<LikesNotifier, LikeState>((ref) {
  return LikesNotifier();
});