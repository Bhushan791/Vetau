import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeAppBar extends StatelessWidget {
  final double rewardPoints;
  final String? profileImageUrl; // URL for network image
  final String? profileImagePath; // Path for local image
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const HomeAppBar({
    super.key,
    this.rewardPoints = 0,
    this.profileImageUrl,
    this.profileImagePath,
    this.onNotificationTap,
    this.onProfileTap,
  });

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
          // 🔔 Left side: Notification + Vetau text
          Row(
            children: [
              GestureDetector(
                onTap: onNotificationTap,
                child: CircleAvatar(
                  radius: 25 * iconScale.clamp(0.8, 1.3),
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
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
                          rewardPoints.toStringAsFixed(2),
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
                onTap: onProfileTap,
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
    
    // If profile image URL exists (from API/Firebase)
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
    
    // If local profile image path exists (from device)
    if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: AssetImage(profileImagePath!),
        onBackgroundImageError: (exception, stackTrace) {
          // Error handling
        },
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