class VideoData {
  final int id;
  final String hlsUrl;
  final String avtorId;
  final String description;
  final int likeCount;
  final int commentCount;
  final bool? isLiked;
  
  VideoData({
    required this.id,
    required this.hlsUrl,
    required this.avtorId,
    required this.description,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'],
      hlsUrl: json['hlsUrl'],
      avtorId: json['avtorId'],
      description: json['description'],
      likeCount: json['likeCount'],
      isLiked: json['isLiked'],
      commentCount: json['commentCount']
    );
  }
}