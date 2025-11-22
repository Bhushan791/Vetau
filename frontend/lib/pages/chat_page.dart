import 'package:flutter/material.dart';
import 'package:frontend/models/chat_model.dart';

class ChatPage extends StatelessWidget {
  final ChatModel chat;

  const ChatPage({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(chat.otherParticipant.fullName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Chat with ${chat.otherParticipant.fullName}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}