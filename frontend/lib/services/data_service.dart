import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty || token == 'null') return null;
    return token;
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/users/search?query=${Uri.encodeComponent(query)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to search users');
  }

  Future<void> sendInvite(int receiverId) async {
    final token = await _getToken();
    if (token == null) return;
    await http.post(
      Uri.parse('${Config.baseUrl}/api/users/invites'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'receiverId': receiverId}),
    );
  }

  Future<List<dynamic>> getInvites() async {
    final token = await _getToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/users/invites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to get invites');
  }
  
  Future<Map<String, dynamic>?> respondInvite(int id, String status) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
    final response = await http.put(
      Uri.parse('${Config.baseUrl}/api/users/invites/$id'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Failed to respond invite');
  }

  Future<void> updateProfile(String? aboutMe, XFile? image) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
    var request = http.MultipartRequest('PUT', Uri.parse('${Config.baseUrl}/api/users/profile'));
    request.headers['Authorization'] = 'Bearer $token';
    if(aboutMe != null) request.fields['aboutMe'] = aboutMe;
    if(image != null) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'profilePicture',
        bytes,
        filename: image.name,
      ));
    }
    final response = await request.send();
    if(response.statusCode != 200) throw Exception('Failed to update profile');
  }

  Future<Map<String, dynamic>> getProfile() async {
     final token = await _getToken();
     if (token == null) throw Exception('Authentication required');
     final response = await http.get(
       Uri.parse('${Config.baseUrl}/api/users/profile'),
       headers: {'Authorization': 'Bearer $token'},
     );
     if(response.statusCode == 200) return jsonDecode(response.body);
     throw Exception('Failed to load profile');
  }
}

class ChatService {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty || token == 'null') return null;
    return token;
  }

  Future<List<dynamic>> getChats() async {
    final token = await _getToken();
    if (token == null) return [];
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/chats'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load chats');
  }

  Future<List<dynamic>> getMessages(int chatId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/chats/$chatId/messages'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load messages');
  }

  Future<void> sendMessage(int chatId, String? content, XFile? media, String type) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
    var request = http.MultipartRequest('POST', Uri.parse('${Config.baseUrl}/api/chats/$chatId/messages'));
    request.headers['Authorization'] = 'Bearer $token';
    if(content != null) request.fields['content'] = content;
    request.fields['type'] = type;
    
    if(media != null) {
      final bytes = await media.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'media',
        bytes,
        filename: media.name,
      ));
    }
    
    final response = await request.send();
    if(response.statusCode != 200) throw Exception('Failed to send message');
  }

  Future<void> deleteChat(int id) async {
    final token = await _getToken();
    if (token == null) return;
    await http.delete(Uri.parse('${Config.baseUrl}/api/chats/$id'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> markRead(int id) async {
    final token = await _getToken();
    if (token == null) return;
    await http.put(Uri.parse('${Config.baseUrl}/api/chats/$id/read'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> editMessage(int chatId, int msgId, String content) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
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
    if (token == null) throw Exception('Authentication required');
    final response = await http.delete(
      Uri.parse('${Config.baseUrl}/api/chats/$chatId/messages/$msgId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if(response.statusCode != 200) throw Exception('Failed to delete message');
  }
  
  Future<void> archiveChat(int id) async {
    final token = await _getToken();
    if (token == null) return;
    await http.post(Uri.parse('${Config.baseUrl}/api/chats/$id/archive'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> unarchiveChat(int id) async {
    final token = await _getToken();
    if (token == null) return;
    await http.post(Uri.parse('${Config.baseUrl}/api/chats/$id/unarchive'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> createGroupChat(String groupName, List<int> userIds) async {
    final token = await _getToken();
    if (token == null) throw Exception('Authentication required');
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/api/chats/group'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'groupName': groupName,
        'userIds': userIds,
      }),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create group');
  }
}
