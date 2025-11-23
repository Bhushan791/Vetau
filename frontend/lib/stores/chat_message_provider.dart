import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/models/message_model.dart';

/// Family provider because each chat room has separate messages
final chatMessagesProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, List<MessageModel>, String>((ref, roomId) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<MessageModel>> {
  ChatMessagesNotifier() : super([]);

  /// Replace entire message list (used on first load)
  void setMessages(List<MessageModel> messages) {
    state = messages;
  }

  /// Add new incoming message (from me or socket)
  void addMessage(MessageModel message) {
    state = [...state, message];
  }

  /// Insert older messages at the top for pagination
  void insertOlderMessages(List<MessageModel> olderMessages) {
    state = [...olderMessages, ...state];
  }

  /// Clear messages when leaving chat screen
  void clear() {
    state = [];
  }
}
