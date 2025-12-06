import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';



class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this.navigatorKey) {
    _initLocalNotifications();
  }

  void _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings("@mipmap/ic_launcher");
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (payload) {
        navigatorKey.currentState?.pushNamed('/notifications');
      },
    );
  }

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



  //foreground notification handling
  void firebaseInit(){
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if(kDebugMode) {
        print("Foreground Notification Received: ${notification?.title}");
        print("notification body: ${notification?.body}");
      }

      if (Platform.isAndroid){
        showNotification(message); 
      }
    });
  }

  // function to show notification
  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
    message.notification!.android!.channelId.toString(), 
    message.notification!.android!.channelId.toString(), 
    importance: Importance.high,
    showBadge: true,
    playSound: true,
    );

    //android notification details
    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channel.id.toString(),
      channel.name.toString(),
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: channel.sound,
      ticker: 'ticker',
    );

    NotificationDetails notificationDetails = NotificationDetails(android: androidDetails); 


    //show notification
    await _localNotifications.show(
      0,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
      payload: 'Notification Payload',
    );
  }

  //background and terminated state notification handling
  Future<void> setupInteractedMessage() async {
   //background state
   FirebaseMessaging.onMessageOpenedApp.listen((message) {
    handleMessage(message);
   });

   //terminated state
   FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data.isNotEmpty) {
        handleMessage(message);
      }
   });
  }

  //handle message
  Future <void> handleMessage(RemoteMessage message) async{
    navigatorKey.currentState?.pushNamed('/notifications');
  } 
}
