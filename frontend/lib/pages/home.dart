import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/pages/detail_home.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/homeAppBar.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/filter_component.dart';
import 'package:frontend/stores/filter_store.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/posts");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        setState(() {
          posts = parsed["data"]["posts"]; // ✅ Correct extraction
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load posts");
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: HomeAppBar(
            rewardPoints: 120.76,
            onNotificationTap: () {},
            onProfileTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ),
        body: Consumer(
          builder: (context, ref, child) {
            final selectedFilters = ref.watch(filterStoreProvider);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Component
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: FilterComponent(),
                  ),

                  // Display Selected Filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      selectedFilters.isEmpty
                          ? "No filters selected"
                          : "You selected: ${selectedFilters.join(', ')}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Posts List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: posts.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailHome(postId: posts[index]["postId"]),
                                  ),
                                );
                                },
                                child: PostCard(post: posts[index]),
                              );
                            },
                          ),
                  )
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 0),
      ),
    );
  }
}



// ---------------------------------------------------------------
//                     POST CARD WIDGET
// ---------------------------------------------------------------

class PostCard extends StatelessWidget {
  final Map post;
  const PostCard({super.key, required this.post});

  // Build image from URL
  Widget _buildImage() {
    final List images = post["images"] ?? [];

    if (images.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 40),
        ),
      );
    }

    return Image.network(
      images[0],
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = post["userId"];
    final String userName =
        (post["isAnonymous"] == true) ? "Anonymous" : (user?["fullName"] ?? "Unknown");

    final reward = post["rewardAmount"] ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildImage(),
          ),

          // Info Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Name
                Text(
                  post["itemName"] ?? "Unnamed Item",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  post["description"] ?? "",
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 8),

                // Reward
                if (reward > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Reward: Rs. $reward",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Location + User
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 4),
                    Text(post["location"] ?? "Unknown"),

                    const Spacer(),

                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
