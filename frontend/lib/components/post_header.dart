import 'package:flutter/material.dart';

class PostHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic> post;
  final String? loggedInUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostHeader({
    super.key,
    required this.user,
    required this.post,
    this.loggedInUserId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = (post["type"] ?? "").toString().toLowerCase();
    
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: user["profileImage"] != null &&
              user["profileImage"].toString().startsWith("http")
            ? NetworkImage(user["profileImage"])
            : null,
          child: user["profileImage"] == null ||
              !user["profileImage"].toString().startsWith("http")
            ? const Icon(Icons.person)
            : null,
          radius: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user["fullName"] ?? "Unknown",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                post["location"] ?? "",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: type == "lost" ? Colors.red : Colors.blue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            type.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        if (post["userId"]?["_id"] == loggedInUserId)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "edit" && onEdit != null) onEdit!();
              if (value == "delete" && onDelete != null) onDelete!();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "edit", child: Text("Edit Post")),
              const PopupMenuItem(value: "delete", child: Text("Delete Post", style: TextStyle(color: Colors.red))),
            ],
          ),
      ],
    );
  }
}