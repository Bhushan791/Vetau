import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/editPost.dart';
import 'package:frontend/stores/like_store.dart';
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
    final type = (post["type"] ?? "").toString().toLowerCase();


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- PROFILE ROW ----------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user["profileImage"] ?? ""),
                radius: 24,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NAME
                    Text(
                      user["fullName"] ?? "Unknown",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),

                    // DATE
                    Text(
                      post["createdAt"] != null
                          ? DateTime.tryParse(post["createdAt"])
                                  ?.toLocal()
                                  .toString()
                                  .split('.')[0] ??
                              ""
                          : "",
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12),
                    ),

                    const SizedBox(height: 6),

                    // TYPE BADGE (LOST/FOUND)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: type == "lost"
                            ? Colors.red.shade600
                            : Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // LOCATION (WRAPS IF LONG)
                    Text(
                      post["location"] ?? "",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      softWrap: true,
                    ),
                  ],
                ),
              ),

              // 3 DOT MENU (ONLY USER WHO POSTED)
              if (post["userId"]?["_id"] == loggedInUserId)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Editpost(),
                        ),
                      );
                    } else if (value == "delete") {
                      deletePost();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "edit",
                      child: Text("Edit Post"),
                    ),
                    const PopupMenuItem(
                      value: "delete",
                      child: Text("Delete Post",
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
            ],
          ),

          const SizedBox(height: 12),
          // TITLE
          Text(
            post["itemName"] ?? "",
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // DESCRIPTION
          Text(post["description"] ?? ""),

          const SizedBox(height: 12),

          // IMAGE
          if (post["images"] != null && post["images"].isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(post["images"][0]),
            ),

          const SizedBox(height: 20),

          // ACTION BUTTONS
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.mode_comment_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat_outlined, color: Colors.white),
            label: const Text(
              "Claim as found",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),

          // COMMENTS SECTION
          Text(
            "Comments (${comments.length})",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          for (int i = 0; i < comments.length; i++)
            buildComment(i, comments[i]),
        ],
      ),
    );
  }

  Widget buildComment(int index, dynamic comment) {
    final likeState = ref.watch(likesProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    NetworkImage(comment["author"]?["profileImage"] ?? ""),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment["author"]?["fullName"] ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    comment["createdAt"] != null
                        ? DateTime.tryParse(comment["createdAt"])
                                ?.toLocal()
                                .toString()
                                .split('.')[0] ??
                            ""
                        : "",
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(comment["text"] ?? ""),

          Row(
            children: [
              IconButton(
                icon: Icon(
                  likeState.likedComments.contains(index.toString())
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color:
                      likeState.likedComments.contains(index.toString())
                          ? Colors.red
                          : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(likesProvider.notifier).toggleLike(
                        index.toString(),
                        comment["likes"] ?? 0,
                      );
                },
              ),
              Text(
                "${likeState.likeCounts[index.toString()] ?? comment["likes"] ?? 0}",
              )
            ],
          ),
        ],
      ),
    );
  }
}
