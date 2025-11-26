import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/controllers/chat_controller.dart';
import 'package:frontend/stores/chat_message_provider.dart';
import 'package:frontend/stores/socket_provider.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String chatId;
  const ChatPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late ChatController chatController;
  bool isTyping = false;
  String typingUser = '';
  XFile? _selectedImage;
  

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
      print('🔧 Socket initialized');
      
      SocketService.instance.joinRoom(widget.chatId);
      await chatController.initSocketListeners();
      print('🔧 Socket listeners initialized');
      
      // Listen for typing indicators - FILTERED BY ROOM ID
      SocketService.instance.onUserTyping((data) {
        if (data['chatId']?.toString() != widget.chatId) return;
        setState(() {
          typingUser = data['fullName'] ?? 'Someone';
        });
      });
      
      SocketService.instance.onUserStopTyping((data) {
        if (data['chatId']?.toString() != widget.chatId) return;
        setState(() {
          typingUser = '';
        });
      });
    } catch (e) {
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

    // Stop typing indicator
    SocketService.instance.sendStopTyping(widget.chatId);
    setState(() => isTyping = false);

    // Send message
    await chatController.sendMessage(text);

    _messageController.clear();
    
    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null) {
      _showImagePreview(image);
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image != null) {
      _showImagePreview(image);
    }
  }

  void _showImagePreview(XFile image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Image.file(
                File(image.path),
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _selectedImage = image);
                      try {
                        await chatController.sendImageMessage(image);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image sent successfully')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Image sending not supported yet'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                      setState(() => _selectedImage = null);
                      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
                    },
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Pick from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take a Photo"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    // Clear messages when leaving chat
    ref.read(chatMessagesProvider(widget.chatId).notifier).clear();
    // Clear socket listeners
    SocketService.instance.clearListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      // Auto-scroll when new message arrives
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (index == messages.length - 1) {
                          _scrollToBottom();
                        }
                      });
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
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _showImageSourceSheet,
                      color: Colors.grey[600],
                    ),
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
                      color: Colors.blue,
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
