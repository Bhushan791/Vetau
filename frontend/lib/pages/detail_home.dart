import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/editPost.dart';
import 'package:frontend/stores/like_store.dart';
import 'package:frontend/components/post_header.dart';
import 'package:frontend/components/post_image.dart';
import 'package:frontend/components/comment_input.dart';
import 'package:frontend/components/comment_item.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DetailHome extends ConsumerStatefulWidget {
  final String postId;
  

  const DetailHome({super.key, required this.postId});

  @override
  ConsumerState<DetailHome> createState() => _DetailHomeState();
}

class _DetailHomeState extends ConsumerState<DetailHome> {
  Map<String, dynamic>? postData;
  bool isLoading = true;
  bool hasError = false;
  String? loggedInUserId;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUserId();
    fetchPost();
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      loggedInUserId = prefs.getString("userId");
    });
  }

  Future<void> fetchPost() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final url =
        "https://vetau.onrender.com/api/v1/posts/${widget.postId}";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          postData = decoded['data']; 
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load post");
      }
    } catch (e) {
      print("Fetch error: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> deletePost() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse("https://vetau.onrender.com/api/v1/posts/${widget.postId}"),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete post: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(likesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Post Details")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Something went wrong"),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: fetchPost,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : buildPostContent(),
    );
  }

  Widget buildPostContent() {
    final post = postData!;
    final comments = post["comments"] ?? [];
    final user = post["userId"] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            user: user,
            post: post,
            loggedInUserId: loggedInUserId,
            onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Editpost())),
            onDelete: deletePost,
          ),
          const SizedBox(height: 16),
          
          Text(
            post["itemName"] ?? "",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          if (post["images"] != null && post["images"].isNotEmpty)
            PostImage(
              images: post["images"],
              rewardAmount: post["rewardAmount"] ?? 0,
            ),
          const SizedBox(height: 16),
          
          Text(
            post["description"] ?? "",
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 8),
          
          Text("Lost Date: ${_formatDate(post["createdAt"])}", style: const TextStyle(fontWeight: FontWeight.w500)),
          Text("Location: ${post["location"] ?? ""}", style: const TextStyle(fontWeight: FontWeight.w500)),
          Text("Reward: Rs. ${post["rewardAmount"] ?? 0}", style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          
          Row(
            children: [
              IconButton(icon: const Icon(Icons.mode_comment_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
              IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_outlined, color: Colors.white),
            label: const Text("Claim as found", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text("Comments (${comments.length})", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                CommentInput(
                  controller: _commentController,
                  onSend: () => _commentController.clear(),
                ),
                const SizedBox(height: 16),
                
                for (int i = 0; i < comments.length; i++)
                  CommentItem(index: i, comment: comments[i]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    return DateTime.tryParse(dateStr)?.toLocal().toString().split(' ')[0] ?? "";
  }





  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
