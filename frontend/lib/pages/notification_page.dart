import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/api_constants.dart';
import 'package:frontend/stores/notifications_provider.dart';
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
        ref.read(notificationsProvider.notifier).fetchNotifications();
      } else if (_tabController.index == 1) {
        fetchMyClaims();
      } else if (_tabController.index == 2) {
        fetchClaimsOnMyPosts();
      }
    });
    ref.read(notificationsProvider.notifier).fetchNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAllNotifications() {
    final notificationsState = ref.watch(notificationsProvider);

    if (notificationsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notificationsState.notifications.isEmpty) {
      return const Center(child: Text('No notifications'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notificationsState.notifications.length,
        itemBuilder: (context, index) {
          final notification = notificationsState.notifications[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: notification.isRead ? Colors.white : Colors.blue.shade50,
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: notification.senderImage.isNotEmpty
                    ? NetworkImage(notification.senderImage)
                    : null,
                child: notification.senderImage.isEmpty
                    ? Text(notification.senderName[0].toUpperCase())
                    : null,
              ),
              title: Text(notification.senderName),
              subtitle: Text(notification.message, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: !notification.isRead
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onTap: () {
                if (!notification.isRead) {
                  ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                }
              },
            ),
          );
        },
      ),
    );
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
