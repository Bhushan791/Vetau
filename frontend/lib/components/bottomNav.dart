import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/stores/badge_count_provider.dart';
import 'package:hugeicons/hugeicons.dart';

class BottomNav extends ConsumerWidget {
  final int currentIndex;

  const BottomNav({
    super.key,
    required this.currentIndex,
  });

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/chats');
        break;
      case 2:
        Navigator.pushNamed(context, '/post');
        break;
      case 3:
        Navigator.pushNamed(context, '/saved');
        break;
      case 4:
        Navigator.pushNamed(context, '/notifications');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeCounts = ref.watch(badgeCountProvider);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            context: context,
            ref: ref,
            icon: HugeIcons.strokeRoundedHome09,
            label: "Home",
            index: 0,
          ),
          _navItem(
            context: context,
            ref: ref,
            icon: HugeIcons.strokeRoundedBubbleChat,
            label: "Chat",
            index: 1,
          ),
          _postButton(context),
          _navItem(
            context: context,
            ref: ref,
            icon: HugeIcons.strokeRoundedBookmark02,
            label: "Saved",
            index: 3,
          ),
          _navItem(
            context: context,
            ref: ref,
            icon: HugeIcons.strokeRoundedNotification02,
            label: "Notification",
            index: 4,
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic icon,
    required String label,
    required int index,
  }) {
    final bool isActive = index == currentIndex;
    final badgeCounts = ref.watch(badgeCountProvider);
    final int badgeCount = index == 4 ? badgeCounts.notificationCount : 0;
    final bool showBadge = index == 4;

    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: -10, end: -6),
            showBadge: showBadge,
            badgeContent: Text(
              badgeCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            badgeAnimation: const badges.BadgeAnimation.scale(
              animationDuration: Duration(milliseconds: 300),
            ),
            badgeStyle: badges.BadgeStyle(
              badgeColor: Colors.red,
              padding: const EdgeInsets.all(4),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: icon,
                color: isActive ? Colors.blue : Colors.black,
                size: 24.0,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _postButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              color: Colors.white,
              size: 28.0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Post",
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          )
        ],
      ),
    );
  }
}
