class VideoData {
  final int id;
  final String hlsUrl;
  final String avtorId;
  final String description;
  int likeCount;
  int commentCount;
  bool? isLiked;
  final String? thumbnailUrl;
  final String? avtorAvatarUrl;
  final String? username;
  VideoData({
    required this.id,
    required this.hlsUrl,
    required this.avtorId,
    required this.description,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.thumbnailUrl,
    required this.avtorAvatarUrl,
    required this.username
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'],
      hlsUrl: json['hlsUrl'],
      avtorId: json['avtorId'],
      description: json['description'],
      likeCount: json['likeCount'],
      isLiked: json['isLiked'],
      commentCount: json['commentCount'],
      thumbnailUrl: json['thumbnailUrl'],
      avtorAvatarUrl: json['avtorAvatarUrl'],
      username: json['avtorName']
    );
  }
}