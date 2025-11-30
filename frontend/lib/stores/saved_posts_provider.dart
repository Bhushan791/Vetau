import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/config/api_constants.dart';
import 'dart:convert';

class SavedPostsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _loadSavedPostsOnce();
    return {};
  }

  Future<void> _loadSavedPostsOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.baseUrl}/saved-posts/my-saved-posts"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed["data"];
        
        List<dynamic> savedPostsList = [];
        if (data is Map && data["savedPosts"] is List) {
          savedPostsList = data["savedPosts"];
        }
        
        final ids = savedPostsList
            .map((item) {
              if (item is Map && item["post"] is Map) {
                return (item["post"]["postId"] ?? item["post"]["_id"] ?? "").toString();
              }
              return "";
            })
            .where((id) => id.isNotEmpty)
            .toSet();
        state = ids;
      }
    } catch (e) {
      print("Error loading saved posts: $e");
    }
  }

  Future<void> toggleSavePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final isSaved = state.contains(postId);

    final previousState = state;
    state = isSaved ? (state..remove(postId)) : (state..add(postId));

    try {
      final url = "${ApiConstants.baseUrl}/saved-posts/${isSaved ? 'unsave' : 'save'}/$postId";
      print("Save API URL: $url");
      
      final response = isSaved
          ? await http.delete(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
          : await http.post(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            );
      
      print("Save response status: ${response.statusCode}");
      print("Save response body: ${response.body}");
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        state = previousState;
        if (response.statusCode == 404) {
          throw Exception("Post not found in database. Please try again later.");
        }
        throw Exception("Failed to toggle save: ${response.statusCode}");
      }
    } catch (e) {
      state = previousState;
      print("Error toggling save: $e");
      rethrow;
    }
  }
}

final savedPostsProvider = NotifierProvider<SavedPostsNotifier, Set<String>>(() {
  return SavedPostsNotifier();
});

class SavingPostNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }
}

final savingPostProvider = NotifierProvider<SavingPostNotifier, String?>(() {
  return SavingPostNotifier();
});
