import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../config/config.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/group_info_dialog.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String title;
  final bool isGroup;

  const ChatScreen({super.key, required this.chatId, required this.title, this.isGroup = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSearchMode = false;
  List<int> _searchResults = [];
  int _currentSearchResultIndex = -1;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.loadMessages(widget.chatId);
      _scrollToBottom();

      _controller.addListener(() {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if(_controller.text.isNotEmpty) {
           if (!_isTyping) {
             _isTyping = true;
             chatProvider.setTyping(true, auth.user!['username']);
           }
           _typingTimer?.cancel();
           _typingTimer = Timer(const Duration(seconds: 2), () {
              _isTyping = false;
              chatProvider.setTyping(false, auth.user!['username']);
           });
        } else {
           if (_isTyping) {
             _isTyping = false;
             _typingTimer?.cancel();
             chatProvider.setTyping(false, auth.user!['username']);
           }
        }
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    Provider.of<ChatProvider>(context, listen: false).leaveChat();
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _currentSearchResultIndex = -1;
      });
      return;
    }
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final List<int> results = [];
    for (int i = 0; i < chatProvider.messages.length; i++) {
      final msg = chatProvider.messages[i];
      if (msg['type'] == 'text' && msg['content'].toString().toLowerCase().contains(query.toLowerCase())) {
        results.add(i);
      }
    }
    setState(() {
      _searchResults = results;
      _currentSearchResultIndex = results.isNotEmpty ? results.length - 1 : -1;
    });
    if (results.isNotEmpty) {
      _jumpToResult(_currentSearchResultIndex);
    }
  }


  void _jumpToResult(int index) {
    if (index < 0 || index >= _searchResults.length) return;
    // Simple estimate for scroll position. In a real app with variable heights, 
    // it's harder, but with itemExtent or similar it's easier. 
    // For now we'll use a rough calculation based on index.
    final targetIndex = _searchResults[index];
    final position = targetIndex * 80.0; // Rough estimate per bubble
    _scrollController.animateTo(
      position,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _sendMessage({String? text, XFile? file, String type = 'text'}) async {
    if ((text == null || text.trim().isEmpty) && file == null) return;
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(text ?? '', file, type, auth.user!);
      if (!mounted) return;
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(picked != null) _sendMessage(file: picked, type: 'image');
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if(picked != null) _sendMessage(file: picked, type: 'video');
  }

  Future<void> _toggleRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audio recording is not yet supported on Web')));
      return;
    }
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _sendMessage(file: XFile(path), type: 'audio');
      }
    } else {
      if (await Permission.microphone.request().isGranted) {
        if(await _audioRecorder.hasPermission()) {
            final tempDir = await getTemporaryDirectory();
            final path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
            await _audioRecorder.start(const RecordConfig(), path: path);
             setState(() => _isRecording = true);
        }
      }
    }
  }

  Future<void> _showEditDialog(dynamic msg) async {
    final editController = TextEditingController(text: msg['content']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: editController),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<ChatProvider>(context, listen: false).editMessage(msg['id'], editController.text);
                Navigator.pop(ctx);
              } catch (e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(int msgId) async {
    try {
      await Provider.of<ChatProvider>(context, listen: false).deleteMessage(msgId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  void _showSecurityInfo(dynamic msg) {
    final encryptionInfo = msg['encryptionInfo'];
    String iv = 'Unknown';
    String ciphertext = 'Unknown';
    
    if (encryptionInfo != null && encryptionInfo.contains(':')) {
      final parts = encryptionInfo.split(':');
      iv = parts[0];
      ciphertext = parts[1];
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.green),
            SizedBox(width: 10),
            Text('Encryption Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Algorithm: AES-256-CBC', style: TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              const Text('Initial Vector (IV):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                child: SelectableText(iv, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
              const SizedBox(height: 10),
              const Text('Ciphertext:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(vertical: 4),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                child: SelectableText(ciphertext, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
              ),
              const Divider(),
              const Text('Note: This is the raw "Encryption at Rest" data as formatted in the SQLite/PostgreSQL database.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildMessage(dynamic msg, bool isMe, String? query) {
    Widget content;
    if (msg['type'] == 'text') {
      final text = msg['content'].toString();
      if (query != null && query.isNotEmpty && text.toLowerCase().contains(query.toLowerCase())) {
        final List<TextSpan> spans = [];
        final lowercaseText = text.toLowerCase();
        final lowercaseQuery = query.toLowerCase();
        int start = 0;
        int indexOfMatch;
        while ((indexOfMatch = lowercaseText.indexOf(lowercaseQuery, start)) != -1) {
          if (indexOfMatch > start) {
            spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
          }
          spans.add(TextSpan(
            text: text.substring(indexOfMatch, indexOfMatch + query.length),
            style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.black),
          ));
          start = indexOfMatch + query.length;
        }
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        content = RichText(text: TextSpan(children: spans, style: const TextStyle(color: Colors.white)));
      } else {
        content = Text(text);
      }
    } else if (msg['type'] == 'image') {
      content = Builder(
        builder: (context) {
          final url = '${Config.baseUrl}/${msg['content']}';
          return Image.network(url, errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
        },
      );
    } else if (msg['type'] == 'video') {
      content = VideoPlayerWidget(videoUrl: msg['content']);
    } else if (msg['type'] == 'audio') {
      content = AudioPlayerWidget(audioUrl: msg['content'], isMe: isMe);
    } else {
      content = const SizedBox.shrink();
    }

    return GestureDetector(
      onLongPress: () {
         showModalBottomSheet(
           context: context,
           builder: (ctx) => Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               if(isMe && msg['type'] == 'text') ListTile(
                 leading: const Icon(Icons.edit),
                 title: const Text('Edit'),
                 onTap: () { Navigator.pop(ctx); _showEditDialog(msg); },
               ),
               if(isMe) ListTile(
                 leading: const Icon(Icons.delete, color: Colors.red),
                 title: const Text('Delete', style: TextStyle(color: Colors.red)),
                 onTap: () { Navigator.pop(ctx); _deleteMessage(msg['id']); },
               ),
               ListTile(
                 leading: const Icon(Icons.security, color: Colors.blue),
                 title: const Text('Security Info'),
                 onTap: () { Navigator.pop(ctx); _showSecurityInfo(msg); },
               ),
             ],
           ),
         );
      },
      child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: isMe 
                     ? (msg['status'] == 'failed' ? Colors.red.withOpacity(0.8) : Colors.deepPurpleAccent) 
                     : const Color(0xFF2C2C3E),
                  borderRadius: BorderRadius.circular(12),
                  border: msg['status'] == 'failed' ? Border.all(color: Colors.redAccent, width: 1) : null,
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      content,
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(msg['User']['username'], style: const TextStyle(fontSize: 10, color: Colors.white54)),
                          const SizedBox(width: 8),
                          Text(
                            msg['createdAt'] != null 
                              ? msg['createdAt'].toString().substring(11, 16) 
                              : '',
                            style: const TextStyle(fontSize: 10, color: Colors.white54),
                          ),
                          if(isMe) ...[
                            const SizedBox(width: 4),
                            Builder(
                              builder: (context) {
                                if (msg['status'] == 'read') {
                                  return const Icon(Icons.done_all, size: 12, color: Colors.blue);
                                } else if (msg['status'] == 'delivered') {
                                  return const Icon(Icons.done_all, size: 12, color: Colors.white54);
                                } else if (msg['status'] == 'sending') {
                                  return const Icon(Icons.access_time, size: 12, color: Colors.white54);
                                } else if (msg['status'] == 'failed') {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Failed. Tap to retry', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => Provider.of<ChatProvider>(context, listen: false).retrySendMessage(msg),
                                        child: const Icon(Icons.error_outline, size: 14, color: Colors.white),
                                      ),
                                    ],
                                  );
                                } else {
                                  return const Icon(Icons.done, size: 12, color: Colors.white54);
                                }
                              }
                            ),
                          ]
                        ],
                      )
                  ]
              )
          )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _isSearchMode 
        ? AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSearchMode = false;
                _searchController.clear();
                _searchResults = [];
                _currentSearchResultIndex = -1;
              }),
            ),
            title: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Search messages...', border: InputBorder.none),
              style: const TextStyle(color: Colors.white),
              onChanged: _performSearch,
            ),
            actions: [
              if (_searchResults.isNotEmpty) ...[
                Center(child: Text('${_currentSearchResultIndex + 1}/${_searchResults.length}')),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: () {
                    setState(() {
                      if (_currentSearchResultIndex > 0) _currentSearchResultIndex--;
                    });
                    _jumpToResult(_currentSearchResultIndex);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () {
                    setState(() {
                      if (_currentSearchResultIndex < _searchResults.length - 1) _currentSearchResultIndex++;
                    });
                    _jumpToResult(_currentSearchResultIndex);
                  },
                ),
              ]
            ],
          )
        : AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isGroup) ...[
                  const Icon(Icons.group, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(widget.title),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearchMode = true),
              ),
              if (widget.isGroup)
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                    final chat = chatProvider.currentChat;
                    if (chat != null && chat['Users'] != null) {
                      showDialog(
                        context: context,
                        builder: (ctx) => GroupInfoDialog(
                          groupName: chat['name'] ?? 'Group',
                          participants: chat['Users'],
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
                builder: (ctx, chatProvider, _) {
                  if (chatProvider.messages.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                  }
                  return ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (ctx, i) {
                     final msg = chatProvider.messages[i];
                     final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
                     final isMe = currentUser != null && msg['User']['id'] == currentUser['id'];
                     return _buildMessage(msg, isMe, _isSearchMode ? _searchController.text : null); 
                  },
                );
              },
            ),
          ),
          Consumer<ChatProvider>(
            builder: (_, chat, __) {
              if (chat.typingUsers.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${chat.typingUsers.keys.join(', ')} is typing...',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
          if(_isRecording) Container(color: Colors.redAccent, padding: const EdgeInsets.all(8), child: const Text('Recording...')),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image), onPressed: _pickImage),
                IconButton(icon: const Icon(Icons.videocam), onPressed: _pickVideo),
                IconButton(icon: Icon(_isRecording ? Icons.stop : Icons.mic), onPressed: _toggleRecording),
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Type a message...'))),
                IconButton(icon: const Icon(Icons.send), onPressed: () => _sendMessage(text: _controller.text)),
              ],
            ),
          ) 
        ],
      ),
    );
  }
}
