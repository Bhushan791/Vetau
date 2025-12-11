// lib/services/fcm_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/main.dart' show navigatorKey, providerContainer;
import 'package:flutter/material.dart';
import 'package:frontend/stores/badge_count_provider.dart';
import 'package:frontend/stores/notifications_provider.dart';
import 'package:frontend/models/notification_model.dart';

class FcmService {
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  FcmService();

  Future<void> init() async {
    // Request notification permissions
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create Android notification channels
    const messagesChannel = AndroidNotificationChannel(
      'messages_channel',
      'Messages',
      description: 'Message notifications',
      importance: Importance.max,
      playSound: true,
    );

    const generalChannel = AndroidNotificationChannel(
      'general_channel',
      'General',
      description: 'General notifications',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(messagesChannel);
    
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    // local notifications init
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _local.initialize(settings, onDidReceiveNotificationResponse: (payload) {
      // when user taps the local system notification, we can route based on payload
      if (payload.payload != null) {
        _handlePayload(Map<String, dynamic>.from({'payload': payload.payload}));
      } else {
        navigatorKey.currentState?.pushNamed('/notifications');
      }
    });

    // Foreground handler
    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) print('FCM onMessage: ${message.data} ${message.notification?.title}');

      final data = message.data;
      final type = data['type'] ?? '';

      // For message notifications, show local pop-up and DO NOT add to in-app notifications.
      if (type == 'message') {
        await _showLocalNotificationForMessage(message);
      } else {
        // non-message: show notification, add to list, and update badge count
        await _showLocalNotificationForGeneric(message);
        _handleNewNotification(data);
      }
    });

    // When user taps notification from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) print('FCM onMessageOpenedApp: ${message.data}');
      _handleMessageRouting(message);
    });

    // initial message when app launched from terminated state
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      if (kDebugMode) print('FCM getInitialMessage: ${initial.data}');
      _handleMessageRouting(initial);
    }
  }

  Future<void> _showLocalNotificationForMessage(RemoteMessage message) async {
    final data = message.data;
    final chatId = data['chatId'] ?? data['conversationId'] ?? '';
    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'Message notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use chatId in payload so tapping local notification opens the chat
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'New message',
      message.notification?.body ?? '',
      notificationDetails,
      payload: jsonEncode({'type': 'message', 'chatId': chatId}),
    );
    
    if (kDebugMode) print('📱 Local notification shown for message');
  }

  Future<void> _showLocalNotificationForGeneric(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      notificationDetails,
      payload: jsonEncode({
        'type': message.data['type'] ?? 'generic',
        'postId': message.data['postId'] ?? '',
        'notificationId': message.data['notificationId'] ?? '',
      }),
    );
    
    if (kDebugMode) print('📱 Local notification shown for generic');
  }

  void _handleMessageRouting(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';

    if (type == 'message') {
      final chatId = data['chatId'] ?? data['conversationId'] ?? '';
      if (chatId.isNotEmpty) {
        navigatorKey.currentState?.pushNamed('/chat_details', arguments: chatId);
      } else {
        navigatorKey.currentState?.pushNamed('/chats');
      }
    } else {
      // Add notification to provider before navigating
      _handleNewNotification(data);
      // For all other notifications (claim, comment, status_update), open Notification page
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      // Create notification model from FCM data
      final notification = NotificationModel(
        notificationId: data['notificationId'] ?? '',
        userId: data['userId'] ?? '',
        type: data['type'] ?? '',
        title: data['title'] ?? '',
        body: data['body'] ?? '',
        data: Map<String, dynamic>.from(data),
        isRead: false,
        isSent: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to notifications list
      providerContainer.read(notificationsProvider.notifier).insertNew(notification);
      
      if (kDebugMode) print('🔔 New notification added to list and badge updated');
    } catch (e) {
      if (kDebugMode) print('Error handling new notification: $e');
    }
  }

  void _handlePayload(Map<String, dynamic> payload) {
    try {
      final raw = payload['payload'];
      if (raw == null) {
        navigatorKey.currentState?.pushNamed('/notifications');
        return;
      }
      final Map<String, dynamic> data = raw is String ? jsonDecode(raw) : Map<String, dynamic>.from(raw);
      final type = data['type'] ?? '';
      
      if (type == 'message') {
        final chatId = data['chatId'] ?? '';
        if (chatId.isNotEmpty) {
          navigatorKey.currentState?.pushNamed('/chat_details', arguments: chatId);
        } else {
          navigatorKey.currentState?.pushNamed('/chats');
        }
      } else {
        // For all other notifications (claim, comment, status_update), open Notification page
        navigatorKey.currentState?.pushNamed('/notifications');
      }
    } catch (e) {
      if (kDebugMode) print('Error handling payload: $e');
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }
}
