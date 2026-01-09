import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/data_service.dart';
import '../config/config.dart';
import 'dart:io';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  IO.Socket? _socket;
  
  List<dynamic> _chats = [];
  List<dynamic> _messages = [];
  int? _currentChatId;
  int _pendingInvites = 0;

  List<dynamic> get chats => _chats;
  List<dynamic> get messages => _messages;
  int get pendingInvites => _pendingInvites;

  void initSocket(String userToken, int userId) {
    if(_socket != null) {
       // If socket exists, check if we need to reconnect (e.g. token changed or simple reconnect)
       // For simplicity, force reconnect if called
       _socket!.disconnect();
    }
    _socket = IO.io(Config.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $userToken'} // Auth
    });
    _socket!.connect();
    
    _socket!.onConnect((_) {
      print('Socket connected');
      // Identify self
      _socket!.emit('identify', userId);
      updatePendingInvitesCount(); // Sync count on connect
      // Re-join active chats
      for(var chat in _chats) {
        _socket!.emit('join_chat', chat['id']);
      }
    });

    _socket!.on('new_invite', (_) {
      _pendingInvites++;
      notifyListeners();
    });
    
    _socket!.on('chat_created', (data) {
       print('New chat created: $data');
       loadChats();
    });

    _socket!.on('update_message', (data) {
       int idx = _messages.indexWhere((m) => m['id'].toString() == data['id'].toString());
       if(idx != -1) {
          _messages[idx] = data;
          notifyListeners();
       }
    });

    _socket!.on('delete_message', (data) {
       _messages.removeWhere((m) => m['id'].toString() == data['id'].toString());
       notifyListeners();
    });

    _socket!.on('typing', (data) {
       if(_currentChatId != null && 
          data['chatId'].toString() == _currentChatId.toString()) {
          _typingUsers[data['username']] = true;
          notifyListeners();
       }
    });

    _socket!.on('stop_typing', (data) {
       if(_currentChatId != null && 
          data['chatId'].toString() == _currentChatId.toString()) {
          _typingUsers.remove(data['username']);
          notifyListeners();
       }
    });

    _socket!.on('new_message', (data) {
        // ... (existing code for new_message) ...
        // Debug incoming message
       print('Received new_message: $data');
       if(_currentChatId != null && 
          data['ChatId'].toString() == _currentChatId.toString()) {
         _messages.add(data);
         // Mark as read immediately if viewing
         markRead(_currentChatId!);
         notifyListeners();
       }
       // Also update chat list lastMessage
       int idx = _chats.indexWhere((c) => c['id'].toString() == data['ChatId'].toString());
       if(idx != -1) {
          _chats[idx]['lastMessageAt'] = DateTime.now().toIso8601String();
          // Update unread count if not in this chat
          if(_currentChatId == null || _currentChatId.toString() != data['ChatId'].toString()) {
             _chats[idx]['unreadCount'] = (_chats[idx]['unreadCount'] ?? 0) + 1;
          }
          // Move to top
          var chat = _chats.removeAt(idx);
          _chats.insert(0, chat);
          notifyListeners();
       } else {
          // New chat? Reload chats
          loadChats();
       }
    });

  }

  final Map<String, bool> _typingUsers = {};
  Map<String, bool> get typingUsers => _typingUsers;

  void setTyping(bool isTyping, String username) {
    if(_socket == null || _currentChatId == null) return;
    if(isTyping) {
      _socket!.emit('typing', {'chatId': _currentChatId, 'username': username});
    } else {
      _socket!.emit('stop_typing', {'chatId': _currentChatId, 'username': username});
    }
  }

  Future<void> editMessage(int msgId, String newContent) async {
    try {
      await _chatService.editMessage(_currentChatId!, msgId, newContent);
      // Wait for socket update_message
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> deleteMessage(int msgId) async {
    try {
      await _chatService.deleteMessage(_currentChatId!, msgId);
      // Wait for socket delete_message
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> archiveChat(int chatId) async {
    try {
      await _chatService.archiveChat(chatId);
      _chats.removeWhere((c) => c['id'] == chatId);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  // ... (rest of the class) ...
  Future<void> updatePendingInvitesCount() async {
     try {
       // Optional: Fetch actual count from API to sync
        final UserService userService = UserService();
        final invites = await userService.getInvites();
        _pendingInvites = invites.length;
        notifyListeners();
     } catch(e) {
        if(e is UnauthorizedException) rethrow;
        print(e);
     }
  }

  Future<void> loadChats() async {
    try {
      _chats = await _chatService.getChats();
      // Join all chat rooms to receive updates
      if(_socket != null) {
        for(var chat in _chats) {
           _socket!.emit('join_chat', chat['id']);
        }
      }
      notifyListeners();
    } catch (e) {
      if (e is UnauthorizedException) rethrow;
      print(e);
    }
  }

  Future<void> markRead(int chatId) async {
     // Optimistic update
     int idx = _chats.indexWhere((c) => c['id'] == chatId);
     if(idx != -1) {
       _chats[idx]['unreadCount'] = 0;
       notifyListeners();
     }
     try {
       await _chatService.markRead(chatId);
     } catch (e) {
       print(e);
     }
  }

  Future<void> loadMessages(int chatId) async {
    _currentChatId = chatId;
    _typingUsers.clear(); // Clear typing status when switching chats
    _socket!.emit('join_chat', chatId);
    // Mark read
    markRead(chatId);
    try {
      _messages = await _chatService.getMessages(chatId);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> sendMessage(String text, File? media, String type) async {
    if(_currentChatId == null) return;
    try {
      await _chatService.sendMessage(_currentChatId!, text, media, type);
      // Socket will handle incoming new message event
    } catch (e) {
      print(e);
      rethrow;
    }
  }
  
  void leaveChat() {
    _currentChatId = null;
    _messages = [];
    _typingUsers.clear();
  }

  void disconnect() {
    if(_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
  }
}
