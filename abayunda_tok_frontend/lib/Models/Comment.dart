class Comment {
  final int id;
  final int videoId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      videoId: json['videoId'],
      userId: json['userId'],
      userName: json['userName'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}