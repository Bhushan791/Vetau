import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;

class PostCard extends StatelessWidget {
  final Map post;
  final VoidCallback onTap;
  final Widget? actionMenu;
  final bool showStatus;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.actionMenu,
    this.showStatus = false,
  });

  Widget _buildImage(String url) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.black12),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),
            Center(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox(),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = post["images"] ?? [];
    final url = (images.isNotEmpty && images[0].toString().startsWith("http"))
        ? images[0]
        : null;

    final user = post["userId"];
    final reward = post["rewardAmount"] ?? 0;
    final userName = post["isAnonymous"] == true
        ? "Anonymous"
        : (user?["fullName"] ?? "Unknown");

    final location = post["location"];
    final locationText = location is String
        ? location
        : (location is Map ? (location["name"] ?? "Unknown") : "Unknown");

    final status = post["status"];
    final type = post["type"] ?? "";

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: url != null
                    ? _buildImage(url)
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 40),
                        ),
                      ),
              ),
              if (actionMenu != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: actionMenu!,
                ),
            ],
          ),
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (reward > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C32),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_money_sharp, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "Rs. $reward",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: type == "lost" ? Colors.redAccent : const Color(0xFF2196F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (showStatus && status != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: status == "active"
                                    ? Colors.green
                                    : status == "claimed" || status == "returned"
                                        ? Colors.blue
                                        : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post["itemName"] ?? "Unnamed Item",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post["description"] ?? "",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationText,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
