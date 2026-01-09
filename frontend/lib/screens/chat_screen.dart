import 'dart:io';
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
import '../widgets/message_search_delegate.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String title;

  const ChatScreen({super.key, required this.chatId, required this.title});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Timer? _typingTimer;

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
           chatProvider.setTyping(true, auth.user!['username']);
           _typingTimer?.cancel();
           _typingTimer = Timer(const Duration(seconds: 2), () {
              chatProvider.setTyping(false, auth.user!['username']);
           });
        } else {
           // Text cleared, stop typing immediately
           chatProvider.setTyping(false, auth.user!['username']);
           _typingTimer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    Provider.of<ChatProvider>(context, listen: false).leaveChat();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage({String? text, File? file, String type = 'text'}) async {
    if ((text == null || text.trim().isEmpty) && file == null) return;
    try {
      await Provider.of<ChatProvider>(context, listen: false).sendMessage(text ?? '', file, type);
      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(picked != null) _sendMessage(file: File(picked.path), type: 'image');
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if(picked != null) _sendMessage(file: File(picked.path), type: 'video');
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _sendMessage(file: File(path), type: 'audio');
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

  Widget _buildMessage(dynamic msg, bool isMe) {
    return GestureDetector(
      onLongPress: isMe ? () {
         showModalBottomSheet(
           context: context,
           builder: (ctx) => Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               if(msg['type'] == 'text') ListTile(
                 leading: const Icon(Icons.edit),
                 title: const Text('Edit'),
                 onTap: () { Navigator.pop(ctx); _showEditDialog(msg); },
               ),
               ListTile(
                 leading: const Icon(Icons.delete, color: Colors.red),
                 title: const Text('Delete', style: TextStyle(color: Colors.red)),
                 onTap: () { Navigator.pop(ctx); _deleteMessage(msg['id']); },
               ),
             ],
           ),
         );
      } : null,
      child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: isMe ? Colors.deepPurpleAccent : const Color(0xFF2C2C3E),
                  borderRadius: BorderRadius.circular(12)
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      if(msg['type'] == 'text') Text(msg['content']),
                      if(msg['type'] == 'image') Builder(
                        builder: (context) {
                          final url = '${Config.baseUrl}/${msg['content']}';
                          return Image.network(url, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
                        }
                      ),
                      if(msg['type'] == 'video') VideoPlayerWidget(videoUrl: msg['content']),
                      if(msg['type'] == 'audio') AudioPlayerWidget(audioUrl: msg['content'], isMe: isMe),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(msg['User']['username'], style: const TextStyle(fontSize: 10, color: Colors.white54)),
                          if(isMe) ...[
                            const SizedBox(width: 4),
                              Icon(
                                msg['status'] == 'read' 
                                  ? Icons.done_all 
                                  : (msg['status'] == 'delivered' ? Icons.done_all : Icons.done),
                                size: 12,
                                color: msg['status'] == 'read' 
                                  ? Colors.blue 
                                  : (msg['status'] == 'delivered' ? Colors.white : Colors.white54),
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
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final chatProvider = Provider.of<ChatProvider>(context, listen: false);
              final result = await showSearch(
                context: context,
                delegate: MessageSearchDelegate(messages: chatProvider.messages),
              );
              if (result != null) {
                // In a more advanced app, we'd scroll to the message
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found at index: ${chatProvider.messages.indexOf(result)}')));
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
                 WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                 return ListView.builder(
                  controller: _scrollController,
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (ctx, i) {
                     final msg = chatProvider.messages[i];
                     final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
                     final isMe = currentUser != null && msg['User']['id'] == currentUser['id'];
                     return _buildMessage(msg, isMe); 
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
