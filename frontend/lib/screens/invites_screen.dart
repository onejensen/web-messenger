import 'package:flutter/material.dart';
import '../services/data_service.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import '../config/config.dart';

class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key});

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _InvitesScreenState extends State<InvitesScreen> {
  final UserService _userService = UserService();
  List<dynamic> _invites = [];

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  Future<void> _loadInvites() async {
    try {
      final list = await _userService.getInvites();
      setState(() => _invites = list);
    } catch(e) {
      // handle error
    }
  }

  Future<void> _respond(int id, String status, String senderName) async {
    try {
      final result = await _userService.respondInvite(id, status);
      
      // Update global count
      if(!mounted) return;
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.updatePendingInvitesCount();

      if (status == 'accepted' && result != null && result['chat'] != null) {
         // Refresh global chat list so Home is updated
         chatProvider.loadChats();
         
         // Navigate to chat
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => 
            ChatScreen(chatId: result['chat']['id'], title: senderName)
         ));
      } else {
        _loadInvites(); // Refresh local list
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invite $status')));
      }
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Invites')),
      body: _invites.isEmpty 
          ? const Center(child: Text('No pending invites'))
          : ListView.builder(
              itemCount: _invites.length,
              itemBuilder: (ctx, i) {
                final invite = _invites[i];
                return ListTile(
                   title: Text(invite['Sender']['username']),
                   subtitle: Text(invite['groupName'] != null 
                       ? 'Invitation to group: ${invite['groupName']}' 
                       : 'Wants to chat with you'),
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _respond(invite['id'], 'accepted', invite['Sender']['username'])),
                       IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _respond(invite['id'], 'declined', invite['Sender']['username'])),
                     ],
                   ),
                );
              },
            ),
    );
  }
}
