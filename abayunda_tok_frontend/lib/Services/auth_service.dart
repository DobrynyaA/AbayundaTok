import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
class AuthService {
  static const String _baseUrl = 'https://10.0.2.2:7000/api/Auth';
  final SharedPreferences _prefs;

  AuthService(this._prefs);

  Future<bool> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/login');
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    final ioClient = IOClient(client);
    try {
      final response = await ioClient.post(
        uri,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final token = jsonDecode(response.body)['token'];
        await _prefs.setString('jwt_token', token);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    } finally {
      client.close(); // Закрываем клиент
    }
  }

  Future<bool> register(String email, String password, String username) async {
    final uri = Uri.parse('$_baseUrl/register');
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true; // Отключаем проверку сертификата

    final ioClient = IOClient(client);
    try {
      final response = await ioClient.post(
        uri,
        body: jsonEncode({
          'email': email,
          'password': password,
          'userName': username,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Exception: $e');
      return false;
    }
  }


  Future<bool> isLoggedIn() async {
    return _prefs.getString('jwt_token') != null;
  }

  Future<String?> getToken() async {
    return _prefs.getString('jwt_token');
  }

  Future<String?> getUserName() async{
    final token = await getToken();
  if (token == null) return null;

  try {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true; // Отключаем проверку сертификата

    final ioClient = IOClient(client);

    final response = await ioClient.get(
      Uri.parse('https://10.0.2.2:7000/api/Test'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = response.body;
      if (responseBody is String) {
        return responseBody.replaceAll('Привет, ', '').replaceAll('!', '');
      }
    }
    return null;
  } catch (e) {
    print('Exception: $e');
    return null;
  }
  }

  Future<void> logout() async {
    await _prefs.remove('jwt_token');
  }

    Future<String?> getUserIdFromToken() async {
      try {
        final token = await getToken(); 
        if (token == null) return null;
        
        final decodedToken = JwtDecoder.decode(token);
        print('Decoded token: $decodedToken');
        
        final userId = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']?.toString();
        
        if (userId == null) {
          print('User ID not found in token claims');
        }
        
        return userId;
      } catch (e) {
        print('Error getting user ID from token: $e');
        return null;
      }
    }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      final ioClient = IOClient(client);

      final response = await ioClient.get(
        Uri.parse('https://10.0.2.2:7000/api/Profile/my'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      if (response.statusCode == 401) {
        await logout();
        return null;
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserProfileById(String userId) async {
  try {
    final response = await http.get(
      Uri.parse('https://10.0.2.2:7000/api/Profile/$userId'), 
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); 
    }

    throw Exception('Ошибка сервера: ${response.statusCode}');
  } catch (e) {
    print('Ошибка при загрузке профиля: $e');
    throw e;
  }
}
}