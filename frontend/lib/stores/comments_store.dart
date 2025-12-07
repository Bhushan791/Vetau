// lib/stores/comments_store.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/models/comment_model.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// State
class CommentsState {
  final bool isLoading;
  final List<CommentModel> comments;
  final String? error;

  CommentsState({
    required this.isLoading,
    required this.comments,
    this.error,
  });

  CommentsState copyWith({bool? isLoading, List<CommentModel>? comments, String? error}) {
    return CommentsState(
      isLoading: isLoading ?? this.isLoading,
      comments: comments ?? this.comments,
      error: error,
    );
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  CommentsNotifier() : super(CommentsState(isLoading: false, comments: []));

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<void> fetchComments(String postId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _getToken();
      final url = "${ApiConstants.baseUrl}/comments/post/$postId";

      final resp = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = decoded['data'] ?? {};
        final rawComments = (data['comments'] as List<dynamic>?) ?? [];

        final comments = rawComments
            .map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
            .toList();

        state = state.copyWith(isLoading: false, comments: comments, error: null);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load comments');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Post a new top-level comment (parentCommentId == null) or reply (parentCommentId provided)
  Future<bool> postComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final token = await _getToken();
      final url = "${ApiConstants.baseUrl}/comments";
      final body = {
        'postId': postId,
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      };

      final resp = await http.post(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        final newCommentJson = decoded['data'] as Map<String, dynamic>;

        final newComment = CommentModel.fromJson(newCommentJson);

        // If backend returns a top-level array of comments where replies are nested,
        // a simple and safe approach is to refetch comments after posting.
        // But to be more efficient, we try to insert locally:
        if (parentCommentId == null) {
          // prepend top-level comment
          state = state.copyWith(comments: [newComment, ...state.comments]);
        } else {
          // insert into correct parent recursively
          final updated = _insertReply(state.comments, parentCommentId, newComment);
          state = state.copyWith(comments: updated);
        }
        return true;
      } else {
        print('Post comment failed: ${resp.statusCode} ${resp.body}');
        return false;
      }
    } catch (e) {
      print('Post comment error: $e');
      return false;
    }
  }

  List<CommentModel> _insertReply(List<CommentModel> list, String parentId, CommentModel reply) {
    return list.map((c) {
      if (c.commentId == parentId) {
        final updatedReplies = [...c.replies, reply];
        return CommentModel(
          commentId: c.commentId,
          content: c.content,
          createdAt: c.createdAt,
          userId: c.userId,
          userName: c.userName,
          userProfileImage: c.userProfileImage,
          parentCommentId: c.parentCommentId,
          isEdited: c.isEdited,
          canEdit: c.canEdit,
          canDelete: c.canDelete,
          isPostOwner: c.isPostOwner,
          replies: updatedReplies,
        );
      } else if (c.replies.isNotEmpty) {
        return CommentModel(
          commentId: c.commentId,
          content: c.content,
          createdAt: c.createdAt,
          userId: c.userId,
          userName: c.userName,
          userProfileImage: c.userProfileImage,
          parentCommentId: c.parentCommentId,
          isEdited: c.isEdited,
          canEdit: c.canEdit,
          canDelete: c.canDelete,
          isPostOwner: c.isPostOwner,
          replies: _insertReply(c.replies, parentId, reply),
        );
      } else {
        return c;
      }
    }).toList();
  }
}

// Riverpod provider
final commentsProvider = StateNotifierProvider.family<CommentsNotifier, CommentsState, String>(
  (ref, postId) => CommentsNotifier()..fetchComments(postId),
);
