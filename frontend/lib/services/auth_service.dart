import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Connection timed out. Check your internet or server IP.');
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _saveToken(data['token']);
      await _saveUser(data['user']);
      return data;
    } else if (response.statusCode == 403) {
      final data = jsonDecode(response.body);
      throw Exception('UNVERIFIED:${data['email']}');
    } else {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  Future<void> register(String username, String email, String password) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Connection timed out. Check your internet or server IP.');
    });

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }
  
  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) return jsonDecode(userStr);
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _storage.delete(key: 'token');
    await prefs.remove('user');
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/api/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }

  Future<Map<String, dynamic>> verifyRegistration(String email, String code) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/auth/verify-registration'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Connection timed out.');
    });

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (data['token'] != null) {
        await _saveToken(data['token']);
        await _saveUser(data['user']);
      }
      return data;
    } else {
      throw Exception(data['error']);
    }
  }

  Future<void> resendVerification(String email) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/auth/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['error']);
    }
  }
}
