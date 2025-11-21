import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/stores/like_store.dart';

class CommentItem extends ConsumerWidget {
  final int index;
  final dynamic comment;

  const CommentItem({
    super.key,
    required this.index,
    required this.comment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeState = ref.watch(likesProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment["author"]?["profileImage"] != null &&
                comment["author"]["profileImage"].toString().startsWith("http")
              ? NetworkImage(comment["author"]["profileImage"])
              : null,
            child: comment["author"]?["profileImage"] == null ||
                !comment["author"]["profileImage"].toString().startsWith("http")
              ? const Icon(Icons.person, size: 16)
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: "${comment["author"]?["fullName"] ?? "Unknown"} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: comment["text"] ?? ""),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatTime(comment["createdAt"]),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        ref.read(likesProvider.notifier).toggleLike(
                          index.toString(),
                          comment["likes"] ?? 0,
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            likeState.likedComments.contains(index.toString())
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: likeState.likedComments.contains(index.toString())
                                ? Colors.red
                                : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${likeState.likeCounts[index.toString()] ?? comment["likes"] ?? 0}",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return "";
    final date = DateTime.tryParse(dateStr);
    if (date == null) return "";
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) return "${diff.inDays}d";
    if (diff.inHours > 0) return "${diff.inHours}h";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m";
    return "now";
  }
}