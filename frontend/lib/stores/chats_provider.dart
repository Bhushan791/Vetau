import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/models/chat_model.dart';
import 'package:frontend/services/chat_service.dart';

final chatsProvider =
    StateNotifierProvider<ChatsController, List<ChatModel>>((ref) {
  return ChatsController(ref);
});

class ChatsController extends StateNotifier<List<ChatModel>> {
  final Ref ref;

  ChatsController(this.ref) : super([]) {
    loadChats();
  }

  Future<void> loadChats() async {
    try {
      final chats = await ChatService.getChats();
      state = chats;
    } catch (e) {
      print("Error loading chats: $e");
    }
  }

  // Update last message of a chat in real-time
  void updateLastMessage(String chatId, String message) {
    state = state.map((chat) {
      if (chat.chatId == chatId) {
        return ChatModel(
          chatId: chat.chatId,
          postId: chat.postId,
          postType: chat.postType,
          itemName: chat.itemName,
          postImage: chat.postImage,
          otherParticipant: chat.otherParticipant,
          lastMessage: message,
          lastMessageAt: DateTime.now().toIso8601String(),
        );
      }
      return chat;
    }).toList();
  }
}
