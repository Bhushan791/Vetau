import 'package:flutter/material.dart';

class VetauNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  const VetauNav({super.key, this.currentIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 90, // increased to prevent overflow
      color: Colors.white,
      elevation: 8,
      notchMargin: 6,
      shape: const CircularNotchedRectangle(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 6), // adjust vertical balance
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_outlined, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.search, label: 'Search', index: 1),
              const SizedBox(width: 70), // space for FAB
              _buildNavItem(icon: Icons.chat_bubble_outline, label: 'Chats', index: 2),
              _buildNavItem(icon: Icons.apps_outlined, label: 'More', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool isActive = index == currentIndex;
    const Color activeColor = Color(0xFF4E6AF3);

    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: () => onTap?.call(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50, // bigger circle
            width: 50,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28, // bigger icon
              color: isActive ? activeColor : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? activeColor : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class VetauFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  const VetauFAB({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 8,
      backgroundColor: const Color(0xFF4E6AF3),
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 34), // larger icon
    );
  }
}
