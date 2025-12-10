import 'package:flutter/material.dart';
import 'package:frontend/pages/detail_home.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/homeAppBar.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/filter_component.dart';
import 'package:frontend/components/post_card.dart';
import 'package:frontend/stores/filter_store.dart';
import 'package:frontend/stores/posts_provider.dart';
import 'package:frontend/services/socket_service.dart';

// =====================================================================
//                                HOME PAGE
// =====================================================================

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  Key _appBarKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() async {
      await ref.read(postsProvider.notifier).fetchPosts();
      _initializeSocket();
    });
  }

  Future<void> _initializeSocket() async {
    try {
      if (!SocketService.instance.isConnected) {
        await SocketService.instance.initSocket();
        await SocketService.instance.waitForConnection();
        print('🔧 Socket initialized on home page');
      }
    } catch (e) {
      print('❌ Socket initialization error: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isScrolling) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (currentScroll >= maxScroll - 200) {
      _isScrolling = true;
      ref.read(postsProvider.notifier).loadMore().then((_) {
        _isScrolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsState = ref.watch(postsProvider);
    final filters = ref.watch(filterStoreProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: HomeAppBar(
          key: _appBarKey,
          refreshKey: _appBarKey,
          rewardPoints: 120.76,
          onNotificationTap: () => Navigator.pushNamed(context, '/notifications'),
          onProfileTap: () async {
            await Navigator.pushNamed(context, '/profile');
            setState(() => _appBarKey = UniqueKey());
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(postsProvider.notifier).fetchPosts(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: FilterComponent(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Text(
                  filters.summaryText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (postsState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (postsState.error != null)
              SliverFillRemaining(
                child: Center(child: Text('Error: ${postsState.error}')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == postsState.posts.length) {
                        return postsState.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      
                      final post = postsState.posts[index];
                      return PostCard(
                        post: post,
                        onTap: () {
                          final postId = post['postId'] ?? post['_id'];
                          if (postId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailHome(postId: postId.toString()),
                              ),
                            );
                          }
                        },
                      );
                    },
                    childCount: postsState.posts.length + (postsState.isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}


