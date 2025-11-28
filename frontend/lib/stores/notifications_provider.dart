import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:frontend/services/notification_service.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await NotificationService.fetchNotifications();
      state = state.copyWith(notifications: notifications, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == notificationId
                ? NotificationModel(
                    id: n.id,
                    senderId: n.senderId,
                    senderName: n.senderName,
                    senderImage: n.senderImage,
                    type: n.type,
                    message: n.message,
                    relatedId: n.relatedId,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n)
            .toList(),
      );
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(() {
  return NotificationsNotifier();
});
