// lib/widgets/notification_card.dart
import 'package:flutter/material.dart';
import 'package:frontend/models/notification_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend/utils/time_ago.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkRead;

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onTap,
    this.onMarkRead,
  }) : super(key: key);

  // Map status -> pill text & color (Option D behavior)
  Widget _buildStatusPill() {
    // For claims use data["status"] if present
    final type = notification.type;
    String text = '';
    Color color = Colors.blue;

    if (type == 'claim') {
      final s = notification.data['status'] ?? '';
      if (s == 'accepted') {
        text = 'Accepted';
        color = Colors.green;
      } else if (s == 'rejected') {
        text = 'Declined';
        color = Colors.red;
      } else {
        text = (s?.toString().isNotEmpty ?? false) ? s.toString() : 'Claim';
        color = Colors.orange;
      }
    } else if (type == 'comment') {
      text = 'Commented';
      color = Colors.blue;
    } else if (type == 'message') {
      // we don't show messages in in-app list (shouldn't happen), but fallback:
      final count = notification.data['count'] ?? '';
      text = (count != '') ? '$count Messages' : 'Message';
      color = Colors.blue;
    } else if (type == 'status_update') {
      text = 'Update';
      color = Colors.orange;
    } else {
      // fallback: use title first word
      final parts = notification.title.split(' ');
      text = (parts.isNotEmpty) ? parts.first : notification.type;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = notification.isRead ? Colors.white : Colors.blue.shade50;

    // pick avatar from notification.data if available
    final senderImage = notification.data['senderImage'] ?? '';
    final senderName = notification.data['senderName'] ?? notification.title;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[200],
                child: senderImage != ''
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: senderImage,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          placeholder: (c, s) => const SizedBox(width: 44, height: 44),
                          errorWidget: (c, s, e) => Center(child: Text(senderName.isNotEmpty ? senderName[0] : '?')),
                        ),
                      )
                    : Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            senderName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        _buildStatusPill(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${notification.data['postTitle'] ?? ''}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${timeAgo(notification.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
