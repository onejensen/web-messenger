import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class UserService {
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/users/search?query=$query'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to search users');
  }

  Future<void> sendInvite(int receiverId) async {
    final token = await _getToken();
    await http.post(
      Uri.parse('${Config.baseUrl}/api/users/invites'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'receiverId': receiverId}),
    );
  }

  Future<List<dynamic>> getInvites() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/users/invites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    if(response.statusCode == 401) throw UnauthorizedException('Session expired');
    throw Exception('Failed to get invites');
  }
  
  Future<Map<String, dynamic>?> respondInvite(int id, String status) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/api/users/invites/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to respond invite');
  }
  Future<void> updateProfile(String? aboutMe, File? image) async {
    final token = await _getToken();
    var request = http.MultipartRequest('PUT', Uri.parse('${Config.baseUrl}/api/users/profile'));
    request.headers['Authorization'] = 'Bearer $token';
    if(aboutMe != null) request.fields['aboutMe'] = aboutMe;
    if(image != null) {
      request.files.add(await http.MultipartFile.fromPath('profilePicture', image.path));
    }
    final response = await request.send();
    if(response.statusCode != 200) throw Exception('Failed to update profile');
  }

  Future<Map<String, dynamic>> getProfile() async {
     final token = await _getToken();
     final response = await http.get(
       Uri.parse('${Config.baseUrl}/api/users/profile'),
       headers: {'Authorization': 'Bearer $token'},
     );
     if(response.statusCode == 200) return jsonDecode(response.body);
     throw Exception('Failed to load profile');
  }
}

class ChatService {
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<List<dynamic>> getChats() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    if(response.statusCode == 401) throw UnauthorizedException('Session expired');
    throw Exception('Failed to load chats');
  }

  Future<List<dynamic>> getMessages(int chatId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/chats/$chatId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load messages');
  }

  Future<void> sendMessage(int chatId, String? content, File? media, String type) async {
    final token = await _getToken();
    var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/chats/$chatId/messages'));
    request.headers['Authorization'] = 'Bearer $token';
    if(content != null) request.fields['content'] = content;
    request.fields['type'] = type;
    
    if(media != null) {
      request.files.add(await http.MultipartFile.fromPath('media', media.path));
    }
    
    final response = await request.send();
    if(response.statusCode != 200) throw Exception('Failed to send message');
  }

  Future<void> archiveChat(int id) async {
    final token = await _getToken();
    await http.put(Uri.parse('${Config.baseUrl}/api/chats/$id/archive'), headers: {'Authorization': 'Bearer $token'});
  }
  
  Future<void> unarchiveChat(int id) async {
    final token = await _getToken();
    await http.put(Uri.parse('${Config.baseUrl}/api/chats/$id/unarchive'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> markRead(int id) async {
    final token = await _getToken();
    await http.put(Uri.parse('${Config.baseUrl}/api/chats/$id/read'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> editMessage(int chatId, int msgId, String content) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/api/chats/$chatId/messages/$msgId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'content': content}),
    );
    if(response.statusCode != 200) throw Exception('Failed to edit message');
  }

  Future<void> deleteMessage(int chatId, int msgId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/api/chats/$chatId/messages/$msgId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode != 200) throw Exception('Failed to delete message');
  }

  Future<Map<String, dynamic>> createGroupChat(String name, List<int> userIds) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/chats/group'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'groupName': name, 'userIds': userIds}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create group chat');
  }
}
