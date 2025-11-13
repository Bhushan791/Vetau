// lib/models/post.dart
class Post {
  final String id;
  final String title;
  final String category;
  final String location;
  final String reward;
  final String image;
  final int likes;
  final int shares;
  final int saves;

  Post({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.reward,
    required this.image,
    required this.likes,
    required this.shares,
    required this.saves,
  });
}