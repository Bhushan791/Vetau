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
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;

// =====================================================================
//                         KEEPS LIST ITEMS ALIVE
// =====================================================================

class KeepAlive extends StatefulWidget {
  final Widget child;
  const KeepAlive({super.key, required this.child});

  @override
  State<KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// =====================================================================
//                                HOME PAGE
// =====================================================================

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List posts = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;

  final ScrollController _scrollController = ScrollController();
  late ProviderSubscription filterSub;

  @override
  void initState() {
    super.initState();

    // Listen to filter changes
    filterSub = ref.listenManual(filterStoreProvider, (prev, next) {
      fetchPosts(); // reload first page
    });

    fetchPosts(); // first load

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    filterSub.close();
    _scrollController.dispose();
    super.dispose();
  }

  // infinite scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMore) loadMorePosts();
    }
  }

  // Build API URL based on filters
  Uri _buildPostUrl({required int page}) {
    final filters = ref.read(filterStoreProvider);
    final base = "${ApiConstants.baseUrl}/posts?page=$page&limit=10";

    List<String> params = [];

    // Type filter
    if (filters.type != null) {
      params.add("type=${filters.type}");
    }

    // Category filter
    if (filters.categories.isNotEmpty) {
      params.add("category=${filters.categories.join(',')}");
    }

    // High Reward filter
    if (filters.highReward) {
      params.add("highReward=true");
    }

    // Near Me filter
    if (filters.nearMe && filters.location != null) {
      params.add("nearMe=true");
      params.add("latitude=${filters.location!.lat}");
      params.add("longitude=${filters.location!.lng}");
    }

    final url = "$base${params.isNotEmpty ? "&${params.join("&")}" : ""}";

    return Uri.parse(url);
  }

  // First load
  Future<void> fetchPosts() async {
    setState(() => isLoading = true);

    final url = _buildPostUrl(page: 1);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final pagination = parsed["data"]["pagination"];

        setState(() {
          posts = parsed["data"]["posts"];
          hasMore = pagination["hasMore"] ?? false;
          currentPage = 1;
        });
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() => isLoading = false);
  }

  // Pagination
  Future<void> loadMorePosts() async {
    if (isLoadingMore || !hasMore) return;

    setState(() => isLoadingMore = true);

    final nextPage = currentPage + 1;
    final url = _buildPostUrl(page: nextPage);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);

        setState(() {
          posts.addAll(parsed["data"]["posts"]);
          hasMore = parsed["data"]["pagination"]["hasMore"];
          currentPage = nextPage;
        });
      }
    } catch (e) {
      print("Error loading more: $e");
    }

    setState(() => isLoadingMore = false);
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final selectedFilters = ref.watch(filterStoreProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: HomeAppBar(
          rewardPoints: 120.76,
          onNotificationTap: () => Navigator.pushNamed(context, '/notifications'),
          onProfileTap: () => Navigator.pushNamed(context, '/profile'),
        ),
      ),
      body: isLoading
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
                        selectedFilters.summaryText,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  if (index == 2) return const SizedBox(height: 16);

                  final postIndex = index - 3;

                  if (postIndex == posts.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return KeepAlive(
                    child: GestureDetector(
                      onTap: () {
                        final postId = posts[postIndex]["postId"] ??
                            posts[postIndex]["_id"];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailHome(postId: postId.toString()),
                          ),
                        );
                      },
                      child: PostCard(post: posts[postIndex]),
                    ),
                  );
                },
              ),
            ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}

// =====================================================================
//                              OPTIMIZED POST CARD
// =====================================================================

class PostCard extends StatelessWidget {
  final Map post;
  const PostCard({super.key, required this.post});

  Widget _buildImage(String url) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black12),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey[300]),
              ),
            ),
            Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = post["images"] ?? [];
    final url = (images.isNotEmpty && images[0].toString().startsWith("http"))
        ? images[0]
        : null;

    final user = post["userId"];
    final reward = post["rewardAmount"] ?? 0;

    final userName = post["isAnonymous"] == true
        ? "Anonymous"
        : (user?["fullName"] ?? "Unknown");

    final location = post["location"];
    final locationText = location is String
        ? location
        : (location is Map ? (location["name"] ?? "Unknown") : "Unknown");

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          url != null
              ? _buildImage(url)
              : Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (reward > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_money_sharp,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                Text(
                  post["itemName"] ?? "Unnamed Item",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  post["description"] ?? "",
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(locationText)),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
