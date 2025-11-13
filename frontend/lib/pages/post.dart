import 'package:flutter/material.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/homeAppBar.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
              backgroundColor: Colors.blue,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: HomeAppBar(
            rewardPoints: 120.76,
            onNotificationTap: () {
              print("Notification tapped");
            },
            onProfileTap: () {
              print("Profile tapped");
            },
          ),
        ),
        body: const Center(
          child: Text(
            'Posts Page',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 2),
      ),
    );
  }
}