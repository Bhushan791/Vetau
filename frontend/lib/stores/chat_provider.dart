import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesController, List<Map>>((ref) {
  return ChatMessagesController();
});

class ChatMessagesController extends StateNotifier<List<Map>> {
  ChatMessagesController() : super([]);

  void addMessage(Map msg) {
    state = [...state, msg];
  }

  void clear() {
    state = [];
  }
}
