import 'dart:convert';
import 'package:abayunda_tok_frontend/Models/VideoData.dart';
import 'package:http/http.dart' as http;

class VideoService {
  final String _baseUrl;

  VideoService({required String baseUrl}) : _baseUrl = baseUrl;

  Future<List<String>> fetchVideosUrls(int page, int limit) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/Video/lenta?page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['hlsUrl'] as String).toList();
      } else {
        throw Exception('Failed to load videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<VideoData> fetchVideoDetails(String videoUrl) async {
    final uri = Uri.parse(videoUrl);
    final segments = uri.pathSegments;
    final guid = segments.length >= 2 ? segments[segments.length - 2] : videoUrl;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/Video/$guid/metadata'),
      );

      if (response.statusCode == 200) {
        return VideoData.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load video details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}