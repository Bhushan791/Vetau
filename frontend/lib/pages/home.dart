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
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List posts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMore) {
        loadMorePosts();
      }
    }
  }

  Future<void> fetchPosts() async {
    final url = Uri.parse("${ApiConstants.baseUrl}/posts?page=1&limit=10");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final pagination = parsed["data"]["pagination"];

        setState(() {
          posts = parsed["data"]["posts"];
          hasMore = pagination["hasMore"] ?? false;
          currentPage = 1;
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

  Future<void> loadMorePosts() async {
    if (isLoadingMore || !hasMore) return;

    setState(() => isLoadingMore = true);

    final nextPage = currentPage + 1;
    final url = Uri.parse("${ApiConstants.baseUrl}/posts?page=$nextPage&limit=10");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final newPosts = parsed["data"]["posts"];
        final pagination = parsed["data"]["pagination"];

        setState(() {
          posts.addAll(newPosts);
          hasMore = pagination["hasMore"] ?? false;
          currentPage = nextPage;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print("Error loading more: $e");
      setState(() => isLoadingMore = false);
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

            return isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchPosts,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: posts.length + 3 + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: FilterComponent(),
                        );
                      }
                      
                      if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
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
                        );
                      }
                      
                      if (index == 2) {
                        return const SizedBox(height: 16);
                      }
                      
                      final postIndex = index - 3;
                      
                      if (postIndex == posts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailHome(postId: posts[postIndex]["postId"]),
                            ),
                          );
                        },
                        child: PostCard(post: posts[postIndex]),
                      );
                    },
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

    final String rawUrl = images[0]?.toString() ?? "";
    final bool isNetwork = rawUrl.toLowerCase().startsWith("http");

    if (!isNetwork || rawUrl.trim().isEmpty) {
      // Not a network image: show placeholder (prevents file:/// errors)
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, size: 40),
        ),
      );
    }

    // At this point we have a valid network URL. Show reddit-style card:
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image (cover) + dark overlay
            Image.network(
              rawUrl,
              fit: BoxFit.cover,
              // don't crash app while loading
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(color: Colors.black12);
              },
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
            ),

            // Blur + darken layer
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
              child: Container(
                color: Colors.black.withOpacity(0.35),
              ),
            ),

            // Foreground full image centered (shows full vertical image)
            Center(
              child: Image.network(
                rawUrl,
                fit: BoxFit.contain,
                // ensure it doesn't overflow; gives full image view
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox.shrink();
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          ],
        ),
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
          // Image (Reddit-style)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: _buildImage(),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // REWARD + LOST/FOUND ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reward
                    if (reward > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8C32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.attach_money_sharp, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Reward: Rs. $reward",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(width: 30),

                    // LOST / FOUND tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: post["type"] == "lost"
                            ? Colors.redAccent
                            : Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (post["type"] ?? "").toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

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

                const SizedBox(height: 10),

                // Location + User
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 4),

                    // Wrapping Location
                    Expanded(
                      child: Text(
                        post["location"] ?? "Unknown",
                        softWrap: true,
                      ),
                    ),

                    const SizedBox(width: 8),

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
