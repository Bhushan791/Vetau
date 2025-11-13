import 'package:flutter/material.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/homeAppBar.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
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
            'Chats Page',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      ),
    );
  }
}