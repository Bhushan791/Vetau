// lib/utils/time_ago.dart
String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);

  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 4) return '${weeks}w ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
