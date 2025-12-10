// lib/stores/badge_count_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeCountState {
  final int notificationCount;
  final int chatCount;
  const BadgeCountState({this.notificationCount = 0, this.chatCount = 0});
}

final badgeCountProvider = NotifierProvider<BadgeCountNotifier, BadgeCountState>(() {
  return BadgeCountNotifier();
});

class BadgeCountNotifier extends Notifier<BadgeCountState> {
  @override
  BadgeCountState build() {
    // start with default and fetch
    fetchBadgeCounts();
    return const BadgeCountState();
  }

  Future<void> fetchBadgeCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      if (token == null) return;

      final res = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final unread = body['data']?['unreadCount'] ?? 0;
        state = BadgeCountState(notificationCount: unread, chatCount: state.chatCount);
      } else {
        state = BadgeCountState(notificationCount: 0, chatCount: state.chatCount);
      }
    } catch (e) {
      state = BadgeCountState(notificationCount: 0, chatCount: state.chatCount);
    }
  }

  void setNotificationCount(int count) {
    print('🔔 Setting notification count to: $count');
    state = BadgeCountState(notificationCount: count, chatCount: state.chatCount);
  }

  void decrementNotification() {
    final newCount = (state.notificationCount - 1) < 0 ? 0 : (state.notificationCount - 1);
    state = BadgeCountState(notificationCount: newCount, chatCount: state.chatCount);
  }

  void incrementNotification() {
    state = BadgeCountState(notificationCount: state.notificationCount + 1, chatCount: state.chatCount);
  }

  void setChatCount(int c) {
    state = BadgeCountState(notificationCount: state.notificationCount, chatCount: c);
  }
}
