import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/models/message_model.dart';

class ChatMessagesState {
  final List<MessageModel> messages;
  final bool isLoading;

  ChatMessagesState({
    required this.messages,
    required this.isLoading,
  });

  ChatMessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
  }) {
    return ChatMessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Family provider because each chat room has separate messages
final chatMessagesProvider = StateNotifierProvider.family<
    ChatMessagesNotifier, ChatMessagesState, String>((ref, roomId) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<ChatMessagesState> {
  final Set<String> _processedMessageIds = {};
  
  ChatMessagesNotifier() : super(ChatMessagesState(messages: [], isLoading: true));

  /// Replace entire message list (used on first load)
  void setMessages(List<MessageModel> messages) {
    state = state.copyWith(messages: messages, isLoading: false);
    _processedMessageIds.clear();
    _processedMessageIds.addAll(messages.map((m) => m.messageId));
  }

  /// Add new incoming message (from me or socket) - prevent duplicates
  void addMessage(MessageModel message) {
    if (_processedMessageIds.contains(message.messageId)) {
      print('⚠️ Duplicate message ignored: ${message.messageId}');
      return;
    }
    
    _processedMessageIds.add(message.messageId);
    state = state.copyWith(messages: [...state.messages, message]);
  }

  /// Insert older messages at the top for pagination
  void insertOlderMessages(List<MessageModel> olderMessages) {
    state = state.copyWith(messages: [...olderMessages, ...state.messages]);
  }

  /// Clear messages when leaving chat screen
  void clear() {
    state = ChatMessagesState(messages: [], isLoading: true);
    _processedMessageIds.clear();
  }
}
