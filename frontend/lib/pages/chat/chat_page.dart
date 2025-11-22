import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/stores/chat_provider.dart';
import 'package:frontend/stores/socket_provider.dart';


class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String myId;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.myId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    final socket = ref.read(socketServiceProvider);

    // Join conversation room
    socket.joinRoom(widget.conversationId);

    // Listen for incoming messages
    socket.onMessage((data) {
      ref.read(chatMessagesProvider.notifier).addMessage(data);
    });
  }

  void sendMessage() {
    if (controller.text.isEmpty) return;

    final socket = ref.read(socketServiceProvider);

    final messageData = {
      "roomId": widget.conversationId,
      "senderId": widget.myId,
      "text": controller.text,
      "timestamp": DateTime.now().toString(),
    };

    socket.sendMessage(messageData);

    // Add to local UI immediately
    ref.read(chatMessagesProvider.notifier).addMessage(messageData);

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
      ),
      body: Column(
        children: [
          // MESSAGES LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg["senderId"] == widget.myId;

                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(
                          color: isMe ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),

          // INPUT FIELD
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(hintText: "Type a message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
