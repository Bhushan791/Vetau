import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print('Chat ID: ${widget.chatId}');
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    print('🚀 fetchMessages called');
    if (!mounted) {
      print('❌ Widget not mounted, returning');
      return;
    }
    
    try {
      print('📱 Getting SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      print('🔑 Token retrieved: ${token != null ? 'Found' : 'Not found'}');
      
      if (token == null) {
        print('❌ No access token found');
        if (mounted) {
          setState(() => isLoading = false);
        }
        return;
      }
      
      final apiUrl = '${ApiConstants.baseUrl}/chats/${widget.chatId}/messages/';
      print('🌐 Calling API: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      print('Messages API response status: ${response.statusCode}');
      print('Messages API response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Response data keys: ${data.keys.toList()}');
        if (data['data'] != null) {
          print('📊 Data keys: ${data['data'].keys.toList()}');
        }
        
        final messagesList = data['data']['messages'] ?? [];
        print('Messages count: ${messagesList.length}');
        
        if (mounted) {
          setState(() {
            messages = messagesList;
            isLoading = false;
          });
        }
      } else {
        print('Failed to fetch messages: ${response.statusCode}');
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      print('Error fetching messages: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message['isMine'] ?? false;
                    
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
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
                            if (message['messageType'] == 'image' && 
                                message['media'] != null && 
                                message['media'].isNotEmpty)
                              Image.network(
                                message['media'][0],
                                height: 200,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              ),
                            if (message['content'] != null && message['content'].toString().isNotEmpty)
                              Text(
                                message['content'].toString(),
                                style: TextStyle(
                                  color: isMine ? Colors.white : Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}