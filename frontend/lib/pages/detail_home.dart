import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/editPost.dart';
import 'package:frontend/stores/like_store.dart';
import 'package:frontend/components/post_header.dart';
import 'package:frontend/components/post_image.dart';
import 'package:frontend/components/comment_input.dart';
import 'package:frontend/components/comment_item.dart';
import 'package:frontend/config/api_constants.dart';
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

    // Handle location - can be String or Map
    final location = post["location"];
    final String locationText = location is String 
        ? location 
        : (location is Map ? (location["name"] ?? "Unknown") : "Unknown");
    
    // Handle user name
    final String userName = (post["isAnonymous"] == true) 
        ? "Anonymous" 
        : (user is Map ? (user["fullName"] ?? "Unknown") : "Unknown");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: user is Map && user["profileImage"] != null
                    ? NetworkImage(user["profileImage"])
                    : null,
                child: user is Map && user["profileImage"] == null
                    ? Text(userName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_formatDate(post["createdAt"]), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (loggedInUserId != null && user is Map && user["_id"] == loggedInUserId)
                PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: "edit", child: Text("Edit")),
                    const PopupMenuItem(value: "delete", child: Text("Delete")),
                  ],
                  onSelected: (value) {
                    if (value == "edit") Navigator.push(context, MaterialPageRoute(builder: (_) => Editpost()));
                    if (value == "delete") deletePost();
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  post["itemName"] ?? "",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: post["type"] == "lost"
                      ? Colors.redAccent
                      : const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  (post["type"] ?? "").toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
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
          
          Text("Location: $locationText", style: const TextStyle(fontWeight: FontWeight.w500)),
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
            onPressed: _showClaimDialog,
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
                
                if (comments.isNotEmpty)
                  ...comments.asMap().entries.map((entry) {
                    final comment = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text((comment["userId"]?["fullName"]?[0] ?? "U").toUpperCase()),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comment["userId"]?["fullName"] ?? "Unknown",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(comment["text"] ?? ""),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
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

  void _showClaimDialog() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Send a message request"),
        content: TextField(
          controller: messageController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Enter your message",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isEmpty) return;
              Navigator.pop(context);
              await _sendClaimRequest(messageController.text.trim());
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendClaimRequest(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');

    try {
      final url = "${ApiConstants.baseUrl}/claims/";
      print("Sending claim to: $url");
      print("PostId: ${widget.postId}");
      print("Message: $message");
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'postId': widget.postId,
          'message': message,
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Claim request sent successfully")),
          );
        }
      } else {
        throw Exception("Failed to send claim: ${response.body}");
      }
    } catch (e) {
      print("Claim error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }





  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
