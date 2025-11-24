import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/services/token_service.dart';
import 'package:frontend/stores/chat_message_provider.dart';
import 'package:frontend/stores/chats_provider.dart';
import 'package:frontend/services/chat_service.dart';

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
    final response = await _client.get(
      Uri.parse("https://vetau.onrender.com/api/v1/chats/$roomId/messages"),
    );

    final jsonBody = jsonDecode(response.body);
    final List messagesJson = jsonBody["data"]["messages"];

    final messages =
        messagesJson.map((m) => MessageModel.fromJson(m)).toList();

    ref.read(chatMessagesProvider(roomId).notifier).setMessages(messages);
  }

  /// ---------------------------
  /// LOAD OLDER MESSAGES
  /// ---------------------------
  Future<void> loadMoreMessages(int page) async {
    final response = await _client.get(
      Uri.parse(
          "https://vetau.onrender.com/api/v1/chats/$roomId/messages?page=$page"),
    );

    final jsonBody = jsonDecode(response.body);
    final List messagesJson = jsonBody["data"]["messages"];

    final older = messagesJson.map((m) => MessageModel.fromJson(m)).toList();

    ref.read(chatMessagesProvider(roomId).notifier).insertOlderMessages(older);
  }

  /// ---------------------------
  /// SEND MESSAGE
  /// ---------------------------
  Future<void> sendMessage(String content) async {
    // Only send via socket - backend handles both persistence and real-time
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

    // Listen for new messages (from others)
    socketService.onNewMessage((data) {
      final message = MessageModel.fromBackendSocket(data, currentUserId: currentUserId);
      ref.read(chatMessagesProvider(roomId).notifier).addMessage(message);
      
      // Update last message in chats list
      ref.read(chatsProvider.notifier).updateLastMessage(roomId, message.content);
    });

    // Listen for message sent confirmation (my messages)
    socketService.onMessageSent((data) {
      final message = MessageModel.fromBackendSocket(data, currentUserId: currentUserId);
      ref.read(chatMessagesProvider(roomId).notifier).addMessage(message);
      
      // Update last message in chats list
      ref.read(chatsProvider.notifier).updateLastMessage(roomId, message.content);
      print('✅ Message sent successfully');
    });

    // Listen for typing indicators
    socketService.onUserTyping((data) {
      // Handle typing indicator
      print('📝 ${data['fullName']} is typing...');
    });

    socketService.onUserStopTyping((data) {
      // Handle stop typing
      print('📝 Stopped typing');
    });

    // Listen for errors
    socketService.onError((error) {
      print('❌ Socket error: ${error['message'] ?? error}');
    });
  }

  Future<String?> _getCurrentUserId() async {
    final token = await TokenService().getAccessToken();
    if (token == null) return null;
    
    final payload = TokenService().decodeToken(token);
    return payload?['_id'];
  }
}
