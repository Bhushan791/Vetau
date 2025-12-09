import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAppBar extends StatefulWidget {
  final double rewardPoints;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final Key? refreshKey;

  const HomeAppBar({
    super.key,
    this.rewardPoints = 0,
    this.onNotificationTap,
    this.onProfileTap,
    this.refreshKey,
  });

  @override
  State<HomeAppBar> createState() => _HomeAppBarState();
}

class _HomeAppBarState extends State<HomeAppBar> {
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  void didUpdateWidget(HomeAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshKey != oldWidget.refreshKey) {
      _loadProfileImage();
    }
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    // Scale factors based on screen size
    final isTablet = width > 600;
    final fontScale = width / 400;
    final iconScale = width / 400;

    return Container(
      padding: EdgeInsets.only(
        left: width * 0.025,
        right: width * 0.025,
        top: height * 0.06,
        bottom: height * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Vetau Logo
          Text(
            "Vetau",
            style: GoogleFonts.kaushanScript(
              fontWeight: FontWeight.w600,
              fontSize: 30 * fontScale.clamp(0.9, 1.4),
            ),
          ),

          // Right side: Buy Me a Coffee + Search + Profile Icon
          Row(
            children: [
              Container(
                width: 150,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEB3B),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.coffee,
                      color: Colors.black,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Buy Me a Coffee ...",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: width * 0.02),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/search'),
                child: const Icon(
                  Icons.search_outlined,
                  color: Colors.black,
                  size: 36,
                ),
              ),
              SizedBox(width: width * 0.02),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: _buildProfileAvatar(iconScale),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(double iconScale) {
    final radius = 20.0;
    
    // If profile image URL exists (from SharedPreferences)
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: NetworkImage(profileImageUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // Error handling - will show fallback icon
        },
        child: null,
      );
    }
    
    // Default fallback icon when no image is available
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue,
      child: Icon(
        Icons.person_outline,
        color: Colors.black54,
        size: 32 * iconScale.clamp(0.8, 1.3),
      ),
    );
  }
}
