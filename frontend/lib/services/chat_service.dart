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

  static Future<File> _forceConvertToJpg(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        debugPrint("Image decode failed for ${file.path}, using original file.");
        return file;
      }

      final jpgBytes = img.encodeJpg(decoded, quality: 85);
      final newPath = file.path.replaceAll(RegExp(r'\.\w+$'), '.jpg');
      final jpgFile = File(newPath);
      await jpgFile.writeAsBytes(jpgBytes, flush: true);
      debugPrint("Converted ${file.path} -> $newPath");
      return jpgFile;
    } catch (e) {
      debugPrint("Error converting image to JPG: $e");
      return file;
    }
  }

  static Future<void> sendImageMessage({
    required String chatId,
    required XFile image,
  }) async {
    // TODO: Backend endpoint for image messages not implemented yet
    // The backend needs to add a POST route for /chats/:chatId/messages that accepts multipart/form-data
    throw Exception('Image sending not supported yet. Backend endpoint needs to be implemented.');
  }
}