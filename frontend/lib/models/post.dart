class Post {
  final String postId;
  final String userId;
  final String type;
  final String itemName;
  final String description;
  final PostLocation location;
  final List<String> images;
  final int rewardAmount;
  final bool isAnonymous;
  final String category;
  final List<String> tags;
  final String status;
  final int totalClaims;
  final int totalComments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PostUser? user;

  Post({
    required this.postId,
    required this.userId,
    required this.type,
    required this.itemName,
    required this.description,
    required this.location,
    required this.images,
    required this.rewardAmount,
    required this.isAnonymous,
    required this.category,
    required this.tags,
    required this.status,
    required this.totalClaims,
    required this.totalComments,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] ?? json['_id'] ?? '',
      userId: json['userId'] is Map ? json['userId']['_id'] ?? '' : json['userId'] ?? '',
      type: json['type'] ?? '',
      itemName: json['itemName'] ?? '',
      description: json['description'] ?? '',
      location: PostLocation.fromJson(json['location']),
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      rewardAmount: json['rewardAmount'] ?? 0,
      isAnonymous: json['isAnonymous'] ?? false,
      category: json['category'] ?? '',
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      status: json['status'] ?? 'active',
      totalClaims: json['totalClaims'] ?? 0,
      totalComments: json['totalComments'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      user: json['userId'] is Map ? PostUser.fromJson(json['userId']) : null,
    );
  }
}

class PostLocation {
  final String name;
  final List<double>? coordinates;

  PostLocation({required this.name, this.coordinates});

  factory PostLocation.fromJson(dynamic json) {
    if (json is String) {
      return PostLocation(name: json, coordinates: null);
    }
    if (json is Map) {
      return PostLocation(
        name: json['name'] ?? 'Unknown',
        coordinates: json['coordinates'] != null
            ? List<double>.from(json['coordinates'].map((c) => c.toDouble()))
            : null,
      );
    }
    return PostLocation(name: 'Unknown', coordinates: null);
  }
}

class PostUser {
  final String id;
  final String fullName;
  final String email;
  final String? profileImage;

  PostUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.profileImage,
  });

  factory PostUser.fromJson(Map<String, dynamic> json) {
    return PostUser(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? 'Unknown',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
    );
  }
}