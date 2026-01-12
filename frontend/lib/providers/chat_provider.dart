import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/data_service.dart';
import '../config/config.dart';
import 'package:image_picker/image_picker.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  IO.Socket? _socket;
  
  List<dynamic> _chats = [];
  List<dynamic> _messages = [];
  int? _currentChatId;
  int _pendingInvites = 0;

  List<dynamic> get chats => _chats;
  List<dynamic> get _sortedChats {
    final list = List<dynamic>.from(_chats);
    list.sort((a, b) {
      final aTime = a['lastMessageAt'] != null ? DateTime.parse(a['lastMessageAt']) : DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b['lastMessageAt'] != null ? DateTime.parse(b['lastMessageAt']) : DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  List<dynamic> get activeChats => _sortedChats.where((c) => (c['isArchived'] == false || c['isArchived'] == null) && (c['isDeleted'] == false || c['isDeleted'] == null)).toList();
  List<dynamic> get archivedChats => _sortedChats.where((c) => c['isArchived'] == true && (c['isDeleted'] == false || c['isDeleted'] == null)).toList();
  List<dynamic> get messages => _messages;
  int get pendingInvites => _pendingInvites;
  Map<String, dynamic>? get currentChat {
    if (_currentChatId == null) return null;
    try {
      return _chats.firstWhere((c) => c['id'].toString() == _currentChatId.toString());
    } catch (_) {
      return null;
    }
  }

  void initSocket(String userToken, int userId) {
    if(_socket != null) {
       // If socket exists, check if we need to reconnect (e.g. token changed or simple reconnect)
       // For simplicity, force reconnect if called
       _socket!.disconnect();
    }
    _socket = IO.io(Config.baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': false,
      'forceNew': true, 
      'auth': {'token': userToken},
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
    });
    _socket!.connect();
    
    _socket!.onConnect((_) {
      debugPrint('ChatProvider: Socket Connected');
      _socket!.emit('identify', userId);
      
      // Auto-rejoin rooms on reconnection
      for(var chat in _chats) {
        debugPrint('ChatProvider: Joining/Re-joining chat ${chat['id']}');
        _socket!.emit('join_chat', chat['id']);
      }
      if(_currentChatId != null) {
        _socket!.emit('join_chat', _currentChatId);
      }
    });

    _socket!.onReconnect((_) {
      debugPrint('ChatProvider: Socket Reconnected');
      loadChats(); // Refresh to ensure no messages were missed during downtime
    });

    _socket!.onDisconnect((reason) {
      debugPrint('ChatProvider: Socket Disconnected. Reason: $reason');
      if (reason == 'io server disconnect') {
        _socket!.connect();
      }
    });

    _socket!.onConnectError((err) {
      debugPrint('ChatProvider: Socket Connect Error: $err');
    });

    _socket!.on('new_invite', (data) {
      debugPrint('ChatProvider: Received new_invite: $data. Refreshing count...');
      updatePendingInvitesCount();
    });
    
    _socket!.on('chat_created', (data) {
       debugPrint('ChatProvider: Received chat_created: $data');
       if (data['id'] != null) {
         debugPrint('ChatProvider: Joining new chat room ${data['id']}');
         _socket!.emit('join_chat', data['id']);
       }
       loadChats();
    });
    
    _socket!.on('new_message', (data) {
       debugPrint('ChatProvider: Received new_message in Room ${data['ChatId']}: ${data['content']}');
       if(_currentChatId != null && 
          data['ChatId'].toString() == _currentChatId.toString()) {
         
         // Deduplicate: check if message ID already exists (from optimistic update)
         int existingIdx = _messages.indexWhere((m) => m['id'].toString() == data['id'].toString());
         if(existingIdx == -1) {
            // Check for optimistic message match (same user, same type, matching content or media)
            int optIdx = _messages.indexWhere((m) => 
               m['id'].toString().startsWith('temp_') && 
               m['User']['id'].toString() == data['UserId'].toString() &&
               (data['type'] == 'text' ? m['content'] == data['content'] : m['type'] == data['type'])
            );

            if(optIdx != -1) {
               debugPrint('ChatProvider: Replacing optimistic message $optIdx with server message ${data['id']} (Type: ${data['type']})');
               _messages[optIdx] = data;
            } else {
               _messages.add(data);
            }
            markRead(_currentChatId!);
            notifyListeners();
         } else {
            // Update the message (e.g. change status from 'sending' to server-confirmed state)
            _messages[existingIdx] = data;
            notifyListeners();
         }

          // Acknowledge delivery if it's from someone else
          if (data['UserId'].toString() != userId.toString()) {
            debugPrint('ChatProvider: Acknowledging delivery of message ${data['id']}');
            _socket!.emit('acknowledge_delivery', {'messageId': data['id'], 'chatId': data['ChatId']});
          }
       }
       
       int idx = _chats.indexWhere((c) => c['id'].toString() == data['ChatId'].toString());
       if(idx != -1) {
          _chats[idx]['lastMessageAt'] = DateTime.now().toIso8601String();
          _chats[idx]['lastMessage'] = data['content']; 
          if(_currentChatId == null || _currentChatId.toString() != data['ChatId'].toString()) {
             _chats[idx]['unreadCount'] = (_chats[idx]['unreadCount'] ?? 0) + 1;
          }
          var chat = _chats.removeAt(idx);
          _chats.insert(0, chat);
          notifyListeners();
       } else {
          debugPrint('ChatProvider: Message for unknown chat, reloading chat list');
          loadChats();
       }
    });

    _socket!.on('update_message', (data) {
       debugPrint('ChatProvider: Received update_message');
       int idx = _messages.indexWhere((m) => m['id'].toString() == data['id'].toString());
       if(idx != -1) {
          _messages[idx] = data;
          notifyListeners();
       }
    });

    _socket!.on('delete_message', (data) {
       debugPrint('ChatProvider: Received delete_message');
       _messages.removeWhere((m) => m['id'].toString() == data['id'].toString());
       notifyListeners();
    });

    _socket!.on('typing', (data) {
       if(_currentChatId != null && data['chatId'].toString() == _currentChatId.toString()) {
          _typingUsers[data['username']] = true;
          notifyListeners();
       }
    });

    _socket!.on('stop_typing', (data) {
       _typingUsers.remove(data['username']);
       notifyListeners();
    });

    _socket!.on('messages_read', (data) {
      debugPrint('ChatProvider: Received messages_read for Chat ${data['chatId']}');
      if(_currentChatId != null && _currentChatId.toString() == data['chatId'].toString()) {
         // Update all messages not sent by the 'readBy' person to 'read'
         for(var i = 0; i < _messages.length; i++) {
            if(_messages[i]['UserId'].toString() != data['readBy'].toString()) {
               _messages[i]['status'] = 'read';
            }
         }
         notifyListeners();
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

  Future<void> deleteChat(int chatId) async {
    try {
      await _chatService.deleteChat(chatId);
      // Update local state isDeleted
      int idx = _chats.indexWhere((c) => c['id'] == chatId);
      if(idx != -1) {
        _chats[idx]['isDeleted'] = true;
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<Map<String, dynamic>?> respondInvite(int id, String status) async {
    try {
      final UserService userService = UserService();
      final result = await userService.respondInvite(id, status);
      await updatePendingInvitesCount();
      if(status == 'accepted') {
        await loadChats();
      }
      return result;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> archiveChat(int chatId) async {
    try {
      await _chatService.archiveChat(chatId);
      int idx = _chats.indexWhere((c) => c['id'] == chatId);
      if(idx != -1) {
        _chats[idx]['isArchived'] = true;
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> unarchiveChat(int chatId) async {
    try {
      await _chatService.unarchiveChat(chatId);
      int idx = _chats.indexWhere((c) => c['id'] == chatId);
      if(idx != -1) {
        _chats[idx]['isArchived'] = false;
        notifyListeners();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> updatePendingInvitesCount() async {
     try {
       // Optional: Fetch actual count from API to sync
        final UserService userService = UserService();
        final invites = await userService.getInvites();
        _pendingInvites = invites.length;
        debugPrint('ChatProvider: updatePendingInvitesCount. Fetched ${invites.length} invites. pendingInvites=$_pendingInvites');
        notifyListeners();
     } catch(e) {
       print(e);
     }
  }

  Future<void> loadChats() async {
    try {
      _chats = await _chatService.getChats();
      debugPrint('ChatProvider: Loaded ${_chats.length} chats');
      // Join all chat rooms to receive updates
      if(_socket != null) {
        for(var chat in _chats) {
           _socket!.emit('join_chat', chat['id']);
        }
      }
      notifyListeners();
    } catch (e) {
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

  Future<void> sendMessage(String text, XFile? media, String type, Map<String, dynamic> currentUser) async {
    if(_currentChatId == null) {
       debugPrint('ChatProvider: Error - _currentChatId is null, cannot send message');
       return;
    }
    
    // Optimistic Update
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final optimisticMsg = {
      'id': 'temp_$tempId',
      'ChatId': _currentChatId,
      'content': text,
      'type': type,
      'status': 'sending',
      'createdAt': DateTime.now().toIso8601String(),
      'User': {
        'id': currentUser['id'],
        'username': currentUser['username'],
        'profilePicture': currentUser['profilePicture']
      }
    };
    _messages.add(optimisticMsg);
    notifyListeners();

    try {
      debugPrint('ChatProvider: Sending message to Chat $_currentChatId: $text');
      final confirmedMsg = await _chatService.sendMessage(_currentChatId!, text, media, type);
      
      // Update optimistic message with real data from server immediately
      int idx = _messages.indexWhere((m) => m['id'] == 'temp_$tempId');
      if (idx != -1) {
        debugPrint('ChatProvider: HTTP success, updating temp_$tempId with real ID ${confirmedMsg['id']}');
        _messages[idx] = confirmedMsg;
        notifyListeners();
      }
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> retrySendMessage(Map<String, dynamic> msg) async {
    final chatId = msg['ChatId'];
    final content = msg['content'];
    final type = msg['type'];
    final tempId = msg['id'];

    // Mark as sending again
    int idx = _messages.indexWhere((m) => m['id'] == tempId);
    if (idx != -1) {
      _messages[idx]['status'] = 'sending';
      notifyListeners();
    }

    try {
      final confirmedMsg = await _chatService.sendMessage(chatId, content, null, type); // For now, retry only text. Media might need more logic if it wasn't uploaded.
      int idx = _messages.indexWhere((m) => m['id'] == tempId);
      if (idx != -1) {
        _messages[idx] = confirmedMsg;
        notifyListeners();
      }
    } catch (e) {
      int idx = _messages.indexWhere((m) => m['id'] == tempId);
      if (idx != -1) {
        _messages[idx]['status'] = 'failed';
        notifyListeners();
      }
      print(e);
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
