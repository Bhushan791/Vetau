import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/stores/notifications_provider.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> myClaims = [];
  List<dynamic> claimsOnMyPosts = [];
  bool isLoading = false;
  bool isLoadingOnMyPosts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        ref.read(notificationsProvider.notifier).refresh();
      } else if (_tabController.index == 1) {
        fetchMyClaims();
      } else if (_tabController.index == 2) {
        fetchClaimsOnMyPosts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAllNotifications() {
    final notificationsAsync = ref.watch(notificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        final filtered = notifications.where((n) => n.type != 'message').toList();
        if (filtered.isEmpty) {
          return const Center(child: Text('No notifications'));
        }
        return RefreshIndicator(
          onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final notification = filtered[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final senderImage = notification.data['senderImage'] ?? '';
    final senderName = notification.data['senderName'] ?? notification.title;
    final postTitle = notification.data['postTitle'] ?? '';
    final timeAgo = _getTimeAgo(notification.createdAt);
    
    String statusText = '';
    Color statusColor = Colors.blue;
    
    if (notification.type == 'claim') {
      final status = notification.data['status'] ?? '';
      if (status == 'accepted') {
        statusText = 'Accepted';
        statusColor = Colors.green;
      } else if (status == 'rejected') {
        statusText = 'Declined';
        statusColor = Colors.red;
      } else {
        statusText = 'Pending';
        statusColor = Colors.orange;
      }
    } else if (notification.type == 'comment') {
      statusText = 'Commented';
      statusColor = Colors.blue;
    } else if (notification.type == 'status_update') {
      statusText = 'Update';
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead ? Colors.white : Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: senderImage.isNotEmpty ? NetworkImage(senderImage) : null,
                child: senderImage.isEmpty && senderName.isNotEmpty ? Text(senderName[0].toUpperCase()) : const Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            senderName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (statusText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14, height: 1.4)),
                        Expanded(
                          child: Text(
                            notification.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (postTitle.isNotEmpty) ...[
                          Flexible(
                            child: Text(
                              'Your post: $postTitle',
                              style: const TextStyle(fontSize: 12, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_getNotificationType(notification.type)} • $timeAgo',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNotificationType(String type) {
    switch (type) {
      case 'claim':
        return 'Claim';
      case 'comment':
        return 'Comment';
      case 'status_update':
        return 'Status Update';
      default:
        return type;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.notificationId, ref);
    }

    final postId = notification.data['postId'] ?? '';
    
    if (postId.isNotEmpty) {
      Navigator.pushNamed(context, '/detailHome', arguments: postId);
    } else if (notification.type == 'claim') {
      _tabController.animateTo(2);
    }
  }

  Future<void> fetchMyClaims() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/claims/my-claims'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          myClaims = data['data']['claims'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching claims: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchClaimsOnMyPosts() async {
    setState(() => isLoadingOnMyPosts = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/claims/on-my-posts/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          claimsOnMyPosts = data['data']['claims'];
          isLoadingOnMyPosts = false;
        });
      } else {
        setState(() => isLoadingOnMyPosts = false);
      }
    } catch (e) {
      print('Error fetching claims on posts: $e');
      setState(() => isLoadingOnMyPosts = false);
    }
  }

  Future<void> updateClaimStatus(String claimId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/claims/$claimId/status/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Claim $status successfully';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        fetchClaimsOnMyPosts();
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to update claim status';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error updating claim status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating claim status: $e')),
      );
    }
  }

  void showClaimActionDialog(String claimId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Claim Status'),
        content: const Text('Do you want to accept or reject this claim?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              updateClaimStatus(claimId, 'rejected');
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              updateClaimStatus(claimId, 'accepted');
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'All Notifications'),
            Tab(text: 'Your Claims'),
            Tab(text: 'Claims on Your Post'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllNotifications(),
          _buildYourClaims(),
          _buildClaimsOnYourPost(),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 4),
    );
  }

  Widget _buildYourClaims() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myClaims.isEmpty) {
      return const Center(child: Text('No claims yet'));
    }

    return RefreshIndicator(
      onRefresh: fetchMyClaims,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myClaims.length,
        itemBuilder: (context, index) {
          final claim = myClaims[index];
          final post = claim['postId'];
          final user = post['userId'];
          final status = claim['status'];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: user['profileImage'] != null
                            ? NetworkImage(user['profileImage'])
                            : null,
                        child: user['profileImage'] == null
                            ? Text(user['fullName'][0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['fullName'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              post['itemName'],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'accepted'
                              ? Colors.green
                              : status == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Message: ${claim['message']}'),
                  const SizedBox(height: 4),
                  Text(
                    'Reward: Rs. ${post['rewardAmount']}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClaimsOnYourPost() {
    if (isLoadingOnMyPosts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (claimsOnMyPosts.isEmpty) {
      return const Center(child: Text('No claims on your posts yet'));
    }

    return RefreshIndicator(
      onRefresh: fetchClaimsOnMyPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: claimsOnMyPosts.length,
        itemBuilder: (context, index) {
          final claim = claimsOnMyPosts[index];
          final post = claim['postId'];
          final claimer = claim['claimerId'];
          final status = claim['status'];

          return GestureDetector(
            onTap: () => showClaimActionDialog(claim['claimId']),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: claimer['profileImage'] != null
                              ? NetworkImage(claimer['profileImage'])
                              : null,
                          child: claimer['profileImage'] == null
                              ? Text(claimer['fullName'][0].toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                claimer['fullName'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                post['itemName'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'accepted'
                                ? Colors.green
                                : status == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Message: ${claim['message']}'),
                    const SizedBox(height: 4),
                    Text(
                      'Reward: Rs. ${post['rewardAmount']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
