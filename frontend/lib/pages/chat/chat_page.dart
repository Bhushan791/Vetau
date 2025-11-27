import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/message_model.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/controllers/chat_controller.dart';
import 'package:frontend/stores/chat_message_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
    _messageController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatController = ref.read(chatControllerProvider(widget.chatId));
      chatController.loadInitialMessages();
      _setupSocketListeners();
    });
  }

  void _setupSocketListeners() async {
    try {
      int retries = 0;
      while (!SocketService.instance.isConnected && retries < 5) {
        await Future.delayed(const Duration(milliseconds: 500));
        retries++;
      }
      
      if (!mounted) return;
      
      if (SocketService.instance.isConnected) {
        SocketService.instance.joinRoom(widget.chatId);
        await chatController.initSocketListeners();
        print('🔧 Socket listeners initialized');
        
        SocketService.instance.onUserTyping((data) {
          if (data['chatId']?.toString() != widget.chatId) return;
          if (mounted) setState(() => typingUser = data['fullName'] ?? 'Someone');
        });
        
        SocketService.instance.onUserStopTyping((data) {
          if (data['chatId']?.toString() != widget.chatId) return;
          if (mounted) setState(() => typingUser = '');
        });
      } else {
        print('⚠️ Socket connection timeout');
      }
    } catch (e) {
      print('❌ Socket setup error: $e');
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    SocketService.instance.sendStopTyping(widget.chatId);
    setState(() => isTyping = false);

    await chatController.sendMessage(text);
    _messageController.clear();
    
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
    SocketService.instance.clearListeners();
    super.dispose();
  }

  String _formatMessageTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatDateHeader(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inDays == 0) {
        return 'Today';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('MMMM d, yyyy').format(date);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (index == messages.length - 1) {
                          _scrollToBottom();
                        }
                      });
                      final message = messages[index];
                      final isMine = message.isMine;
                      final showDateHeader = index == 0 || 
                          (index > 0 && _formatDateHeader(message.createdAt.toString()) != 
                           _formatDateHeader(messages[index - 1].createdAt.toString()));

                      return Column(
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _formatDateHeader(message.createdAt.toString()),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMine) ...[
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey[300],
                                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMine ? const Color(0xFF5B8DEF) : Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (message.messageType == 'image' && message.media.isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                message.media.first,
                                                height: 200,
                                                width: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  height: 200,
                                                  width: 200,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.error),
                                                ),
                                              ),
                                            ),
                                          if (message.content.isNotEmpty)
                                            Text(
                                              message.content,
                                              style: TextStyle(
                                                color: isMine ? Colors.white : Colors.black87,
                                                fontSize: 15,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                      child: Text(
                                        _formatMessageTime(message.createdAt.toString()),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMine) const SizedBox(width: 8),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                if (typingUser.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$typingUser is typing...',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _showImageSourceSheet,
                      color: Colors.grey[700],
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: const Color(0xFF5B8DEF),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
