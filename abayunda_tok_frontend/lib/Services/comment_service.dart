import 'dart:convert';
import 'package:abayunda_tok_frontend/Models/Comment.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

class CommentService {
  final String _baseUrl;
  final AuthService _authService;

  CommentService({required String baseUrl, required AuthService authService})
      : _baseUrl = baseUrl,
        _authService = authService;

  Future<List<Comment>> getComments(int videoId) async {
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/api/Comment/$videoId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  }

  Future<Comment> addComment(int videoId, String text) async {
    final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Comment'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'videoId': videoId,
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      return Comment.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
  }
}