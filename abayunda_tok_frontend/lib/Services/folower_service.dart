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
}