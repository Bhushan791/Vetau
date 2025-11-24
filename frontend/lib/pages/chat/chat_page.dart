import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/controllers/chat_controller.dart';
import 'package:frontend/stores/chat_message_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  const ChatPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late ChatController chatController;
  bool isTyping = false;
  String typingUser = '';
  bool isSocketConnected = false;
  String? socketError;
  

  @override
  void initState() {
    super.initState();

    // Initialize controller
    chatController = ref.read(chatControllerProvider(widget.chatId));

    // Add typing listener
    _messageController.addListener(_onTextChanged);

    // Load messages from API
    chatController.loadInitialMessages();

    // Setup socket
    _initSocket();
  }

  void _initSocket() async {
    try {
      await SocketService.instance.initSocket();
      
      // Monitor connection status
      SocketService.instance.socket.on('connect', (_) {
        setState(() {
          isSocketConnected = true;
          socketError = null;
        });
        print('✅ Socket connected successfully');
      });
      
      SocketService.instance.socket.on('disconnect', (_) {
        setState(() {
          isSocketConnected = false;
        });
        print('❌ Socket disconnected');
      });
      
      SocketService.instance.socket.on('connect_error', (error) {
        setState(() {
          isSocketConnected = false;
          socketError = error.toString();
        });
        print('❌ Socket connection error: $error');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      });
      
      SocketService.instance.joinRoom(widget.chatId);
      await chatController.initSocketListeners();
      
      // Listen for typing indicators
      SocketService.instance.onUserTyping((data) {
        setState(() {
          typingUser = data['fullName'] ?? 'Someone';
        });
      });
      
      SocketService.instance.onUserStopTyping((data) {
        setState(() {
          typingUser = '';
        });
      });
    } catch (e) {
      setState(() {
        isSocketConnected = false;
        socketError = e.toString();
      });
      print('❌ Socket initialization error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to chat server: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!isSocketConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to chat server. Please wait...'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Stop typing indicator
    SocketService.instance.sendStopTyping(widget.chatId);
    setState(() => isTyping = false);

    // Send message
    await chatController.sendMessage(text);

    _messageController.clear();
  }

  void _onTextChanged() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !isTyping) {
      SocketService.instance.sendTyping(widget.chatId);
      setState(() => isTyping = true);
    } else if (text.isEmpty && isTyping) {
      SocketService.instance.sendStopTyping(widget.chatId);
      setState(() => isTyping = false);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    // Clear messages when leaving chat
    ref.read(chatMessagesProvider(widget.chatId).notifier).clear();
    // Clear socket listeners
    SocketService.instance.clearListeners();
    // Clear connection status listeners
    SocketService.instance.socket.off('connect');
    SocketService.instance.socket.off('disconnect');
    SocketService.instance.socket.off('connect_error');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue,
        actions: [
          // Connection status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSocketConnected ? Icons.wifi : Icons.wifi_off,
                  color: isSocketConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  isSocketConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isSocketConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.isMine;

                      return Align(
                        alignment:
                            isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (message.messageType == 'image' &&
                                  message.media.isNotEmpty)
                                Image.network(
                                  message.media.first,
                                  height: 200,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  ),
                                ),
                              if (message.content.isNotEmpty)
                                Text(
                                  message.content,
                                  style: TextStyle(
                                      color: isMine ? Colors.white : Colors.black),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Column(
            children: [
              // Typing indicator
              if (typingUser.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '$typingUser is typing...',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              // Message input
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
