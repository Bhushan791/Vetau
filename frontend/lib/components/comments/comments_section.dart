// lib/components/comments/comments_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/comment_model.dart';
import 'package:frontend/components/comments/comment_item.dart';
import 'package:frontend/components/comments/comment_input.dart';
import 'package:frontend/stores/comments_store.dart';

class CommentsSection extends ConsumerStatefulWidget {
  final String postId;
  final List<dynamic>? initialRawComments; // optional initial comments

  const CommentsSection({
    super.key,
    required this.postId,
    this.initialRawComments,
  });

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  CommentModel? replyingTo;

  @override
  void initState() {
    super.initState();
    // provider is family - watching it will call fetch automatically (as constructed)
    // But if you prefer explicit fetch:
    Future.microtask(() => ref.read(commentsProvider(widget.postId).notifier).fetchComments(widget.postId));
  }

  Future<void> _send(String text) async {
    final success = await ref.read(commentsProvider(widget.postId).notifier).postComment(
          postId: widget.postId,
          content: text,
          parentCommentId: replyingTo?.commentId,
        );

    if (success) {
      // reset reply target
      setState(() => replyingTo = null);
      // optionally show a small animation/snackbar
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to post comment")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commentsProvider(widget.postId));
    final notifier = ref.read(commentsProvider(widget.postId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Text("Comments (${state.comments.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),

        // Input
        CommentInput(
          hint: replyingTo == null ? "Add a comment for this post..." : "Replying to ${replyingTo!.userName}",
          onSend: (txt) async => await _send(txt),
          replyingToName: replyingTo?.userName,
          onCancelReply: () => setState(() => replyingTo = null),
        ),
        const SizedBox(height: 12),

        if (state.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (state.error != null)
          Column(
            children: [
              Text("Error: ${state.error}"),
              TextButton(
                onPressed: () => notifier.fetchComments(widget.postId),
                child: const Text("Retry"),
              ),
            ],
          )
        else
          Column(
            children: state.comments.map((c) => _buildCommentRecursively(c)).toList(),
          ),
      ],
    );
  }

  Widget _buildCommentRecursively(CommentModel comment, [int depth = 0]) {
    return Column(
      children: [
        CommentItem(
          comment: comment,
          depth: depth,
          onReply: (c) {
            setState(() {
              replyingTo = c;
            });
            // scroll to input if needed - depends on parent scroll view
          },
        ),
        if (comment.replies.isNotEmpty)
          Column(
            children: comment.replies.map((r) => _buildCommentRecursively(r, depth + 1)).toList(),
          ),
      ],
    );
  }
}
