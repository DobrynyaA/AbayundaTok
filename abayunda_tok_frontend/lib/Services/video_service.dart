import 'dart:convert';
import 'dart:io';
import 'package:abayunda_tok_frontend/Models/VideoData.dart';
import 'package:abayunda_tok_frontend/Services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VideoService {
  final String _baseUrl;
  final AuthService _authService;
  
  VideoService({required String baseUrl, required AuthService authService}) : _baseUrl = baseUrl, _authService = authService;

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
      final token = await _authService.getToken();

      final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/api/Video/$guid/metadata'),
        headers: headers,
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

  Future<String> putLike(int videoId) async {
    final token = await _authService.getToken();
    final headers = {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/api/Like/$videoId'),
      headers: headers
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to put like: ${response.statusCode}');
    }
  }

  Future<String> removeLike(int videoId) async {
    final token = await _authService.getToken();
      final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      };
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/Like/$videoId'),
      headers: headers
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to remove like: ${response.statusCode}');
    }
  }

  Future<bool> uploadVideo({
    required File videoFile,
    required String description,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) return false;

      final tempFile = await _createTempCopy(videoFile);
      
      final uri = Uri.parse('$_baseUrl/api/Video/upload');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['Description'] = description;
      
      final fileStream = http.ByteStream(tempFile.openRead());
      final length = await tempFile.length();
      
      final multipartFile = http.MultipartFile(
        'VideoFile',
        fileStream,
        length,
        filename: tempFile.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      await tempFile.delete();
      
      return response.statusCode == 500;
    } catch (e) {
      print('Error uploading video: $e');
      return false;
    }
  }

  Future<File> _createTempCopy(File originalFile) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4');
    return await originalFile.copy(tempFile.path);
  }
}