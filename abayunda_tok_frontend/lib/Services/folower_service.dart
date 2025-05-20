import 'dart:convert';
import 'package:abayunda_tok_frontend/Models/Comment.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

class FolowerService {
  final String _baseUrl;
  final AuthService _authService;

  FolowerService({required String baseUrl, required AuthService authService})
      : _baseUrl = baseUrl,
        _authService = authService;
  
  Future<List<dynamic>> getFollowers(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/folowwers/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load followers');
    }
  }

  Future<List<dynamic>> getFollowing(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/folowing/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load followers');
    }
  }
  Future<bool> follow(String? signatoryId) async {
    try {
      final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Follow/follow/$signatoryId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to follow user');
    }
  }

  Future<bool> unfollow(String? signatoryId) async {
    try {
      final token = await _authService.getToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/Follow/unfollow/$signatoryId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Failed to unfollow user');
    }
  }

  Future<bool> isFollowing(String? signatoryId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/Follow/isfollower/$signatoryId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final responseBody = false;
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);  
        if (responseBody is bool) {
          return responseBody;
        } 
        else if (responseBody is Map && responseBody['isFollowing'] != null) {
          return responseBody['isFollowing'] as bool;
        } 
        else if (responseBody is Map && responseBody['success'] != null) {
          return responseBody['success'] as bool;
        }
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to check follow status');
    }
  }
}