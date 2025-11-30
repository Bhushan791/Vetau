import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAppBar extends StatefulWidget {
  final double rewardPoints;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const HomeAppBar({
    super.key,
    this.rewardPoints = 0,
    this.onNotificationTap,
    this.onProfileTap,
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
          // 🔍 Left side: Search + Vetau text
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/search'),
                child: CircleAvatar(
                  radius: 25 * iconScale.clamp(0.8, 1.3),
                  backgroundColor: Colors.grey.shade300,
                  child: Icon(
                    Icons.search_outlined,
                    color: Colors.black,
                    size: 30 * iconScale.clamp(0.8, 1.3),
                  ),
                ),
              ),
              SizedBox(width: width * 0.015),
              Text(
                "Vetau",
                style: GoogleFonts.kaushanScript(
                  fontWeight: FontWeight.w600,
                  fontSize: 30 * fontScale.clamp(0.9, 1.4),
                ),
              ),
            ],
          ),

          // 🌞 Right side: Karma Pill + Profile Icon
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 28 : 20,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C32),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.white,
                          size: 22 * iconScale.clamp(0.9, 1.3),
                        ),
                        SizedBox(width: width * 0.02),
                        Text(
                          widget.rewardPoints.toStringAsFixed(2),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16 * fontScale.clamp(0.9, 1.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Karma Points",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ],
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
    final radius = 25 * iconScale.clamp(0.8, 1.3);
    
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
