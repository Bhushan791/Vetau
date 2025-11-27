import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/token_service.dart';
import 'package:frontend/stores/chat_message_provider.dart';
import 'package:frontend/stores/chats_provider.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final chatControllerProvider =
    Provider.family<ChatController, String>((ref, roomId) {
  return ChatController(ref, roomId);
});

class ChatController {
  final Ref ref;
  final String roomId;

  ChatController(this.ref, this.roomId);

  ApiClient get _client => ApiClient(
        baseUrl: "https://vetau.onrender.com/api/v1",
        onSessionExpired: (context) {
          // handle logout
        },
      );

  /// ---------------------------
  /// LOAD FIRST PAGE
  /// ---------------------------
  Future<void> loadInitialMessages() async {
    final currentUserId = await _getCurrentUserId();
    
    final response = await _client.get(
      Uri.parse("https://vetau.onrender.com/api/v1/chats/$roomId/messages"),
    );

    final jsonBody = jsonDecode(response.body);
    final List messagesJson = jsonBody["data"]["messages"];

    final messages =
        messagesJson.map((m) => MessageModel.fromJson(m, currentUserId: currentUserId)).toList();

    ref.read(chatMessagesProvider(roomId).notifier).setMessages(messages);
  }

  /// ---------------------------
  /// LOAD OLDER MESSAGES
  /// ---------------------------
  Future<void> loadMoreMessages(int page) async {
    final currentUserId = await _getCurrentUserId();
    
    final response = await _client.get(
      Uri.parse(
          "https://vetau.onrender.com/api/v1/chats/$roomId/messages?page=$page"),
    );

    final jsonBody = jsonDecode(response.body);
    final List messagesJson = jsonBody["data"]["messages"];

    final older = messagesJson.map((m) => MessageModel.fromJson(m, currentUserId: currentUserId)).toList();

    ref.read(chatMessagesProvider(roomId).notifier).insertOlderMessages(older);
  }

  /// ---------------------------
  /// SEND MESSAGE
  /// ---------------------------
  Future<void> sendMessage(String content) async {
    SocketService.instance.sendMessage(roomId, content);
  }

  /// ---------------------------
  /// SEND IMAGE MESSAGE
  /// ---------------------------
  Future<void> sendImageMessage(dynamic image) async {
    try {
      await ChatService.sendImageMessage(
        chatId: roomId,
        image: image,
      );
    } catch (e) {
      print('❌ Error sending image: $e');
    }
  }

  /// ---------------------------
  /// SOCKET LISTENERS
  /// ---------------------------
  Future<void> initSocketListeners() async {
    final socketService = SocketService.instance;
    final currentUserId = await _getCurrentUserId();

    // Clear existing listeners to prevent duplicates
    socketService.clearListeners();

    // Listen for messages from others
    socketService.onNewMessage((data) {
      print('📨 Received new_message: chatId=${data['chatId']}, currentRoom=$roomId');
      if (data['chatId']?.toString() != roomId) return;
      
      final message = MessageModel.fromBackendSocket(data, currentUserId: currentUserId);
      ref.read(chatMessagesProvider(roomId).notifier).addMessage(message);
      ref.read(chatsProvider.notifier).updateLastMessage(roomId, message.content);
    });

    // Listen for my sent messages confirmation
    socketService.onMessageSent((data) {
      print('📨 Received message_sent: chatId=${data['chatId']}, currentRoom=$roomId');
      if (data['chatId']?.toString() != roomId) return;
      
      final message = MessageModel.fromBackendSocket(data, currentUserId: currentUserId);
      ref.read(chatMessagesProvider(roomId).notifier).addMessage(message);
      ref.read(chatsProvider.notifier).updateLastMessage(roomId, message.content);
    });

    // Listen for typing indicators
    socketService.onUserTyping((data) {
      if (data['chatId']?.toString() != roomId) return;
      print('📝 ${data['fullName']} is typing...');
    });

    socketService.onUserStopTyping((data) {
      if (data['chatId']?.toString() != roomId) return;
      print('📝 Stopped typing');
    });

    // Listen for errors
    socketService.onError((error) {
      print('❌ Socket error: ${error['message'] ?? error}');
    });
  }

  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    print('🆔 Current user ID from SharedPreferences: $userId');
    return userId;
  }
}
