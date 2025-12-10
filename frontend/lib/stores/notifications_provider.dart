// lib/stores/notifications_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:frontend/services/notification_api.dart';
import 'package:frontend/stores/badge_count_provider.dart';

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(() {
  return NotificationsNotifier();
});

class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  List<NotificationModel> _cache = [];

  @override
  Future<List<NotificationModel>> build() async {
    // initial load
    try {
      final list = await NotificationApi.fetchNotifications();
      _cache = list;
      
      // Update badge count on initial load
      final unreadCount = _cache.where((n) => !n.isRead && n.type != 'message').length;
      ref.read(badgeCountProvider.notifier).setNotificationCount(unreadCount);
      
      return _cache;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final list = await NotificationApi.fetchNotifications();
      _cache = list;
      state = AsyncValue.data(_cache);
      
      // Update badge count after fetching notifications
      final unreadCount = _cache.where((n) => !n.isRead && n.type != 'message').length;
      ref.read(badgeCountProvider.notifier).setNotificationCount(unreadCount);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // mark locally and call API
  Future<void> markAsRead(String notificationId, WidgetRef ref) async {
    try {
      // optimistic update
      _cache = _cache.map((n) {
        if (n.notificationId == notificationId) {
          return NotificationModel(
            notificationId: n.notificationId,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            isRead: true,
            isSent: n.isSent,
            createdAt: n.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return n;
      }).toList();

      state = AsyncValue.data(_cache);
      await NotificationApi.markAsRead(notificationId);

      // update badge count
      final badgeNotifier = ref.read(badgeCountProvider.notifier);
      badgeNotifier.decrementNotification();
    } catch (e) {
      // on error, refresh to get server truth
      await refresh();
    }
  }

  // insert new notification (called e.g. from socket)
  void insertNew(NotificationModel n) {
    // Add to cache first
    _cache.insert(0, n);
    
    // Always update state
    state = AsyncValue.data([..._cache]);
    
    // Update badge count when new notification arrives
    if (n.type != 'message' && !n.isRead) {
      ref.read(badgeCountProvider.notifier).incrementNotification();
    }
  }
}
