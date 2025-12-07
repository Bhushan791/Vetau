// lib/components/comments/comment_item.dart
import 'package:flutter/material.dart';
import 'package:frontend/models/comment_model.dart';
import 'package:intl/intl.dart';

class CommentItem extends StatelessWidget {
  final CommentModel comment;
  final void Function(CommentModel) onReply;
  final int depth;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onReply,
    this.depth = 0,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    if (diff.inDays < 7) return "${diff.inDays}d";
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final leftPadding = depth * 16.0;

    return Padding(
      padding: EdgeInsets.only(left: leftPadding, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // vertical line indicator for replies
          if (depth > 0)
            Container(
              width: 16,
              alignment: Alignment.topCenter,
              child: Container(
                width: 2,
                height: 60,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.only(left: 7),
              ),
            )
          else
            const SizedBox(width: 8),
          // avatar
          CircleAvatar(
            radius: 18,
            backgroundImage:
                comment.userProfileImage != null ? NetworkImage(comment.userProfileImage!) : null,
            child: comment.userProfileImage == null
                ? Text(comment.userName.isNotEmpty ? comment.userName[0] : 'U')
                : null,
          ),
          const SizedBox(width: 10),
          // content box
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.02), blurRadius: 2),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // name + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        comment.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _timeAgo(comment.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(comment.content),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          // handle like if needed (not implemented here)
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.favorite_border, size: 18),
                            SizedBox(width: 6),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onReply(comment),
                        child: Text("Reply", style: TextStyle(color: Colors.blue[700])),
                      ),
                      const SizedBox(width: 8),
                      if (comment.canEdit)
                        Text(" • Edit", style: TextStyle(color: Colors.grey[700])),
                      if (comment.canDelete)
                        Text(" • Delete", style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
