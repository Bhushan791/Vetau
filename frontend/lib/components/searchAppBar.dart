import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onBackPressed;

  const SearchAppBar({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.onBackPressed,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imageUrl = prefs.getString('userProfileImage');
    if (mounted) {
      setState(() {
        profileImageUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black87, size: 18),
          onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
        ),
      ),
      title: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: "Search items, colors, or locations",
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: const TextStyle(fontSize: 18),
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: _buildProfileAvatar(),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[300],
        backgroundImage: NetworkImage(profileImageUrl!),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.blue,
      child: const Icon(
        Icons.person_outline,
        color: Colors.black54,
        size: 24,
      ),
    );
  }
}
