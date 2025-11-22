import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/models/chat_model.dart';
import 'package:frontend/services/api_client.dart';

class ChatService {
  static Future<List<ChatModel>> getChats(BuildContext context) async {
    final apiClient = ApiClient(
      baseUrl: ApiConstants.baseUrl,
      onSessionExpired: (context) {},
    );
    
    final response = await apiClient.get(
      Uri.parse('${ApiConstants.baseUrl}/chats/'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final chats = data['data']['chats'] as List;
      return chats.map((chat) => ChatModel.fromJson(chat)).toList();
    } else {
      throw Exception('Failed to load chats: ${response.statusCode}');
    }
  }
}