class NotificationModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderImage;
  final String type;
  final String message;
  final String relatedId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderImage,
    required this.type,
    required this.message,
    required this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final sender = json['senderId'] ?? {};
    return NotificationModel(
      id: json['_id'] ?? '',
      senderId: sender['_id'] ?? '',
      senderName: sender['fullName'] ?? 'Unknown',
      senderImage: sender['profileImage'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      relatedId: json['relatedId'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
