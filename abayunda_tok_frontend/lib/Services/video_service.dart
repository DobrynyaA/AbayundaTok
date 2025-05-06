import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoService {
  final String _baseUrl;

  VideoService({required String baseUrl}) : _baseUrl = baseUrl;

  Future<List<String>> fetchVideos(int page, int limit) async {
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
}