// lib/models/notification_model.dart
class NotificationModel {
  final String notificationId;
  final String userId;
  final String type; // claim | message | comment | status_update | ...
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool isSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.isSent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return NotificationModel(
      notificationId: json['notificationId'] ?? json['_id'] ?? '',
      userId: json['userId']?.toString() ?? json['user']?.toString() ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: (json['data'] is Map) ? Map<String, dynamic>.from(json['data']) : {},
      isRead: json['isRead'] ?? false,
      isSent: json['isSent'] ?? false,
      createdAt: parseDate(json['createdAt'] ?? json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'notificationId': notificationId,
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'isRead': isRead,
        'isSent': isSent,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
