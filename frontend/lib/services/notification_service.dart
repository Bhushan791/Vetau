import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService(this.navigatorKey) {
    _initLocalNotifications();
  }

  // --------------------------------------------------------------------------
  // LOCAL NOTIFICATION INIT
  // --------------------------------------------------------------------------
  void _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings("@mipmap/ic_launcher");
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (payload) {
        navigatorKey.currentState?.pushNamed('/notifications');
      },
    );
  }

  // --------------------------------------------------------------------------
  // API: FETCH NOTIFICATIONS
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // API: MARK AS READ
  // --------------------------------------------------------------------------
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

  // --------------------------------------------------------------------------
  // FOREGROUND NOTIFICATION HANDLING
  // --------------------------------------------------------------------------
  void firebaseInit() {
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;

      if (kDebugMode) {
        print("🔔 Foreground Notification:");
        print("Title: ${notification?.title}");
        print("Body: ${notification?.body}");
      }

      // Only show local pop-up in Android
      if (Platform.isAndroid) {
        showNotification(message);
      }
    });
  }

  // --------------------------------------------------------------------------
  // LOCAL POP-UP NOTIFICATION
  // --------------------------------------------------------------------------
  Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'default_channel', // static channel
      'General Notifications',
      channelDescription: 'Used for showing notifications while app is open',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
      payload: 'open_notifications',
    );
  }

  // --------------------------------------------------------------------------
  // BACKGROUND & TERMINATED HANDLING
  // --------------------------------------------------------------------------
  Future<void> setupInteractedMessage() async {
    // Background click
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      handleMessage(message);
    });

    // Terminated state
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        handleMessage(message);
      }
    });
  }

  // --------------------------------------------------------------------------
  // NAVIGATION HANDLER
  // --------------------------------------------------------------------------
  Future<void> handleMessage(RemoteMessage message) async {
    navigatorKey.currentState?.pushNamed('/notifications');
  }
}
