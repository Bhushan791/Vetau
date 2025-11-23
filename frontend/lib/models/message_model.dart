class MessageModel {
  final String messageId;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String content;
  final List<String> media;
  final String messageType; // "text" | "image"
  final bool isRead;
  final DateTime createdAt;
  final bool isMine;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.content,
    required this.media,
    required this.messageType,
    required this.isRead,
    required this.createdAt,
    required this.isMine,
  });

  /// PARSING BACKEND JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json["sender"] ?? {};

    return MessageModel(
      messageId: json["messageId"].toString(),
      senderId: sender["_id"]?.toString() ?? "",
      senderName: sender["fullName"] ?? "",
      senderImage: sender["profileImage"] ?? "",
      content: json["content"] ?? "",
      media: json["media"] != null
          ? List<String>.from(json["media"].map((m) => m.toString()))
          : [],
      messageType: json["messageType"] ?? "text",
      isRead: json["isRead"] ?? false,
      createdAt: DateTime.tryParse(json["createdAt"] ?? "") ?? DateTime.now(),
      isMine: json["isMine"] ?? false,
    );
  }

  /// TO JSON (for socket outgoing messages)
  Map<String, dynamic> toJson() {
    return {
      "messageId": messageId,
      "content": content,
      "media": media,
      "messageType": messageType,
      "createdAt": createdAt.toIso8601String(),
      "isMine": isMine,
    };
  }
}
