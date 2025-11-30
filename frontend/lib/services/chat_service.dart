import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/models/chat_model.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/token_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class ChatService {
  static Future<List<ChatModel>> getChats() async {
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

  static Future<void> sendMessage({
    required String chatId,
    required String content,
    required String messageType,
  }) async {
    final apiClient = ApiClient(
      baseUrl: ApiConstants.baseUrl,
      onSessionExpired: (context) {},
    );
    
    final response = await apiClient.post(
      Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/messages'),
      body: json.encode({
        'content': content,
        'messageType': messageType,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to send message: ${response.statusCode}');
    }
  }

  static Future<void> sendImageMessage({
    required String chatId,
    required XFile image,
  }) async {
    try {
      final tokenService = TokenService();
      final token = await tokenService.getAccessToken();

      if (token == null) {
        throw Exception('No access token available');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/messages/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['chatId'] = chatId;
      request.fields['messageType'] = 'image';

      final imageFile = File(image.path);
      request.files.add(
        http.MultipartFile(
          'media',
          imageFile.readAsBytes().asStream(),
          await imageFile.length(),
          filename: image.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send();

      if (response.statusCode != 201) {
        throw Exception('Failed to send image: ${response.statusCode}');
      }

      print('✅ Image sent successfully');
    } catch (e) {
      print('❌ Error sending image: $e');
      throw Exception('Failed to send image: $e');
    }
  }
}
