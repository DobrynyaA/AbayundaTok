class VideoData {
  final String id;
  final String hlsUrl;
  final String avtorId;
  final String description;
  final int likeCount;
  bool isLiked;
  
  VideoData({
    required this.id,
    required this.hlsUrl,
    required this.avtorId,
    required this.description,
    required this.likeCount,
    this.isLiked = false,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'].toString(),
      hlsUrl: json['hlsUrl'],
      avtorId: json['avtorId'],
      description: json['description'],
      likeCount: json['likeCount'],
    );
  }
}