import 'package:flutter/material.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/pages/detail_home.dart';
import 'package:frontend/pages/edit_post_page.dart';
import 'package:frontend/components/post_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color kPrimaryColor = Color(0xFF4285F4);
const Color kLightBlueBackground = Color(0xFFD3E0FB);
const Color kCardBackground = Color(0xFFFFFFFF);
const Color kScaffoldBackground = Color(0xFFF5F6F8);

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _fetchMyPosts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ApiClient(
        baseUrl: ApiConstants.baseUrl,
        onSessionExpired: (ctx) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
          }
        },
      );

      final url = Uri.parse('${ApiConstants.baseUrl}/posts/my-posts?page=$_currentPage&limit=10');
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final postsData = data['data'];
        final List<dynamic> newPosts = postsData['posts'] ?? [];
        final pagination = postsData['pagination'] ?? {};

        setState(() {
          if (refresh) {
            _posts = newPosts;
          } else {
            _posts = List.from(_posts)..addAll(newPosts);
          }
          _hasMore = pagination['hasMore'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load posts';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;
      final client = ApiClient(
        baseUrl: ApiConstants.baseUrl,
        onSessionExpired: (ctx) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
          }
        },
      );

      final url = Uri.parse('${ApiConstants.baseUrl}/posts/my-posts?page=$_currentPage&limit=10');
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final postsData = data['data'];
        final List<dynamic> newPosts = postsData['posts'] ?? [];
        final pagination = postsData['pagination'] ?? {};

        setState(() {
          _posts = List.from(_posts)..addAll(newPosts);
          _hasMore = pagination['hasMore'] ?? false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _currentPage--;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentPage--;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _updatePostStatus(String postId, String status) async {
    try {
      final client = ApiClient(
        baseUrl: ApiConstants.baseUrl,
        onSessionExpired: (ctx) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
          }
        },
      );

      final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId/status/');
      final request = http.Request('PATCH', url);
      request.body = jsonEncode({'status': status});
      request.headers['Content-Type'] = 'application/json';
      
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Status updated to ${status.toUpperCase()}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          _fetchMyPosts(refresh: true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    try {
      final client = ApiClient(
        baseUrl: ApiConstants.baseUrl,
        onSessionExpired: (ctx) {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
          }
        },
      );

      final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId/');
      final request = http.Request('DELETE', url);
      
      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Post deleted successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _fetchMyPosts(refresh: true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete post'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStatusChangeDialog(Map post) {
    final postId = post['postId'] ?? post['_id'];
    final currentStatus = post['status'] ?? 'active';
    final type = post['type'] ?? '';

    if (postId == null) return;

    // Determine available status options based on post type
    String targetStatus;
    String statusLabel;
    if (type == 'found') {
      targetStatus = 'returned';
      statusLabel = 'Returned';
    } else {
      targetStatus = 'claimed';
      statusLabel = 'Claimed';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Post Status', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current status: ${currentStatus.toUpperCase()}'),
            const SizedBox(height: 16),
            Text('Do you want to mark this post as $statusLabel?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePostStatus(postId.toString(), targetStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Mark as $statusLabel'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map post) {
    final postId = post['postId'] ?? post['_id'];
    final itemName = post['itemName'] ?? 'this post';

    if (postId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('Delete Post', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text('Are you sure you want to delete "$itemName"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost(postId.toString());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditPost(Map post) {
    final postId = post['postId'] ?? post['_id'];
    if (postId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditPostPage(postId: postId.toString()),
        ),
      ).then((updated) {
        if (updated == true) {
          _fetchMyPosts(refresh: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackground,
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchMyPosts(refresh: true),
        child: _isLoading && _posts.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
            : _error != null && _posts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _fetchMyPosts(refresh: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: TextStyle(color: Colors.grey[600], fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first post to get started',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return _isLoadingMore
                                ? const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(color: kPrimaryColor),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }

                          final post = _posts[index];
                          final status = post['status'] ?? 'active';
                          final type = post['type'] ?? '';
                          
                          return PostCard(
                            post: post,
                            showStatus: true,
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
                            actionMenu: PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.more_vert, size: 20, color: Colors.black87),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _navigateToEditPost(post);
                                } else if (value == 'delete') {
                                  _showDeleteDialog(post);
                                } else if (value == 'status') {
                                  _showStatusChangeDialog(post);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20, color: Color(0xFF4285F4)),
                                      SizedBox(width: 12),
                                      Text('Edit Post'),
                                    ],
                                  ),
                                ),
                                if (status == 'active')
                                  PopupMenuItem(
                                    value: 'status',
                                    child: Row(
                                      children: [
                                        Icon(
                                          type == 'found' ? Icons.keyboard_return : Icons.check_circle,
                                          size: 20,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(type == 'found' ? 'Mark as Returned' : 'Mark as Claimed'),
                                      ],
                                    ),
                                  ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      SizedBox(width: 12),
                                      Text('Delete Post', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

