import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BadgeCountState {
  final int chatCount;
  final int notificationCount;

  const BadgeCountState({
    this.chatCount = 0,
    this.notificationCount = 0,
  });

  BadgeCountState copyWith({
    int? chatCount,
    int? notificationCount,
  }) {
    return BadgeCountState(
      chatCount: chatCount ?? this.chatCount,
      notificationCount: notificationCount ?? this.notificationCount,
    );
  }
}

class BadgeCountNotifier extends Notifier<BadgeCountState> {
  @override
  BadgeCountState build() {
    fetchBadgeCounts();
    return const BadgeCountState();
  }

  Future<void> fetchBadgeCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        state = state.copyWith(
          notificationCount: data['data']['unreadCount'] ?? 0,
        );
      }
    } catch (e) {
      print('Error fetching badge counts: $e');
    }
  }
}

final badgeCountProvider = NotifierProvider<BadgeCountNotifier, BadgeCountState>(() {
  return BadgeCountNotifier();
});
