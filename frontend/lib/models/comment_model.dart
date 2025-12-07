// lib/models/comment_model.dart
class CommentModel {
  final String commentId;
  final String content;
  final String? parentCommentId;
  final DateTime createdAt;
  final bool isEdited;
  final bool canEdit;
  final bool canDelete;

  // User info (populated by backend under "user")
  final String userId;
  final String userName;
  final String? userProfileImage;
  final bool isPostOwner;

  final List<CommentModel> replies;

  CommentModel({
    required this.commentId,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.userName,
    this.userProfileImage,
    this.parentCommentId,
    this.isEdited = false,
    this.canEdit = false,
    this.canDelete = false,
    this.isPostOwner = false,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final rawReplies = json['replies'] as List<dynamic>? ?? [];

    return CommentModel(
      commentId: json['commentId'] ?? json['_id'] ?? '',
      content: json['content'] ?? json['text'] ?? '',
      parentCommentId: json['parentCommentId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isEdited: json['isEdited'] ?? false,
      canEdit: json['canEdit'] ?? false,
      canDelete: json['canDelete'] ?? false,
      userId: user['_id']?.toString() ?? '',
      userName: user['fullName'] ?? user['username'] ?? 'Unknown',
      userProfileImage: user['profileImage'],
      isPostOwner: user['isPostOwner'] ?? false,
      replies: rawReplies.map((e) => CommentModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'content': content,
      'parentCommentId': parentCommentId,
      'createdAt': createdAt.toIso8601String(),
      'user': {
        '_id': userId,
        'fullName': userName,
        'profileImage': userProfileImage,
      },
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}
