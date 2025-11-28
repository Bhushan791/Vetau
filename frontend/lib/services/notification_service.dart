import 'dart:convert';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static Future<List<NotificationModel>> fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List notifications = data['data']['notifications'] ?? [];
      return notifications.map((n) => NotificationModel.fromJson(n)).toList();
    }
    throw Exception('Failed to fetch notifications');
  }

  static Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/notifications/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
