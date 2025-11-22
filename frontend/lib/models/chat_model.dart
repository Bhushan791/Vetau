class ChatModel {
  final String chatId;
  final String postId;
  final String postType;
  final String itemName;
  final String postImage;
  final OtherParticipant otherParticipant;
  final String lastMessage;
  final String lastMessageAt;

  ChatModel({
    required this.chatId,
    required this.postId,
    required this.postType,
    required this.itemName,
    required this.postImage,
    required this.otherParticipant,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chatId'],
      postId: json['postId'],
      postType: json['postType'],
      itemName: json['itemName'],
      postImage: json['postImage'],
      otherParticipant: OtherParticipant.fromJson(json['otherParticipant']),
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'],
    );
  }
}

class OtherParticipant {
  final String fullName;
  final String email;
  final String profileImage;

  OtherParticipant({
    required this.fullName,
    required this.email,
    required this.profileImage,
  });

  factory OtherParticipant.fromJson(Map<String, dynamic> json) {
    return OtherParticipant(
      fullName: json['fullName'],
      email: json['email'],
      profileImage: json['profileImage'],
    );
  }
}