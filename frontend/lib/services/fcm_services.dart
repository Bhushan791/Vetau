import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> initializeFCM(String userId, String accessToken) async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print("❌ Notification permission denied");
      return;
    }

    String? token = await _fcm.getToken();
    print("🔑 FCM Token: $token");

    if (token != null) {
      await sendTokenToServer(token, accessToken);
    }

    FirebaseMessaging.onMessage.listen((message) {
      print("📩 Foreground notification: ${message.notification?.title}");
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📨 Notification clicked");
    });
  }

  static Future<void> sendTokenToServer(String token, String accessToken) async {
    final res = await http.post(
      Uri.parse("https://vetau.onrender.com/api/v1/users/fcm-token"),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"fcmToken": token}),
    );

    print("FCM token saved: ${res.body}");
  }

  static void _showForegroundNotification(RemoteMessage message) {
    print("📲 Showing foreground notification: ${message.notification?.title}");
  }
}
