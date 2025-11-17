import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/stores/like_store.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailHome extends ConsumerStatefulWidget {
  final String postId; // Accept postId

  const DetailHome({super.key, required this.postId});

  @override
  ConsumerState<DetailHome> createState() => _DetailHomeState();
}

class _DetailHomeState extends ConsumerState<DetailHome> {
  Map<String, dynamic>? postData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchPost();
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
          postData = decoded['data']; // ✅ real data is inside "data"
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load post");
      }
    } catch (e) {
      print("Fetch error: $e"); // useful for debugging
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final likeState = ref.watch(likesProvider);

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
          // ---------------- Author Info ----------------
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user["profileImage"] ?? ""),
                radius: 24,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user["fullName"] ?? "Unknown",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(post["createdAt"] != null
                      ? DateTime.tryParse(post["createdAt"])?.toLocal().toString().split('.')[0] ?? ""
                      : ""),
                ],
              ),
              const Spacer(),

              // Reward
              if (post["rewardAmount"] != null && post["rewardAmount"] > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFD8B02),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "₹${post["rewardAmount"]}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ---------------- Category & Location ----------------
          Row(
            children: [
              Chip(
                label: Text(post["category"] ?? ""),
                backgroundColor: Colors.blue.shade600,
                labelStyle: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              Chip(label: Text(post["location"] ?? "")),
              const SizedBox(width: 8),
              if (post["isAnonymous"] == true)
                const Chip(label: Text("Anonymous")),
            ],
          ),

          const SizedBox(height: 12),

          // ---------------- Title ----------------
          Text(
            post["itemName"] ?? "",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // ---------------- Description ----------------
          Text(post["description"] ?? ""),

          const SizedBox(height: 12),

          // ---------------- Images ----------------
          if (post["images"] != null && post["images"].isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(post["images"][0]),
            ),

          const SizedBox(height: 20),

          // ---------------- Action Buttons ----------------
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
                fontSize: 16,
              ),
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

          // ---------------- Comments Section ----------------
          Text(
            "Comments (${comments.length})",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          // Author
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                    comment["author"]?["profileImage"] ?? ""),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment["author"]?["fullName"] ?? "Unknown",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(comment["createdAt"] != null
                      ? DateTime.tryParse(comment["createdAt"])
                              ?.toLocal()
                              .toString()
                              .split('.')[0] ??
                          ""
                      : ""),
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
                  color: likeState.likedComments.contains(index.toString())
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
