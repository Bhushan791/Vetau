import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/pages/detail_home.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/post_card.dart';
import 'package:frontend/stores/saved_posts_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SavedPosts extends ConsumerStatefulWidget {
  const SavedPosts({super.key});

  @override
  ConsumerState<SavedPosts> createState() => _SavedPostsState();
}

class _SavedPostsState extends ConsumerState<SavedPosts> {
  List<dynamic> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSavedPosts();
  }

  Future<void> fetchSavedPosts() async {
    setState(() => isLoading = true);
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
        
        List<dynamic> postsList = [];
        if (data is Map && data["savedPosts"] is List) {
          postsList = (data["savedPosts"] as List)
              .map((item) => item is Map ? item["post"] : item)
              .toList();
        } else if (data is List) {
          postsList = data;
        }
        
        setState(() {
          posts = postsList;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load saved posts");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Saved Posts"),
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
              ? const Center(child: Text("No saved posts", style: TextStyle(fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: fetchSavedPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      if (post is! Map) return const SizedBox();
                      return PostCard(
                        post: post,
                        onTap: () {
                          final postId = post["postId"] ?? post["_id"];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailHome(postId: postId.toString()),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}


