import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class NewGroupScreen extends StatefulWidget {
  static const routeName = '/new-group';
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _nameController = TextEditingController();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  
  List<dynamic> _contacts = [];
  final List<int> _selectedIds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    // For simplicity, we search all users or just show friends? 
    // Requirement says "User can send group chat invitations to other users"
    // Let's allow searching/listing users. 
    // Simplified for now: just search box and results.
  }

  Future<void> _search(String query) async {
    if(query.isEmpty) return;
    try {
      final results = await _userService.searchUsers(query);
      setState(() => _contacts = results);
    } catch(e) {
      // error
    }
  }

  Future<void> _createGroup() async {
    if(_nameController.text.isEmpty || _selectedIds.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final result = await _chatService.createGroupChat(_nameController.text.trim(), _selectedIds);
      if(!mounted) return;
      Provider.of<ChatProvider>(context, listen: false).loadChats();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group chat created and invites sent!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Group')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Search users to invite...', prefixIcon: Icon(Icons.search)),
              onSubmitted: _search,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (ctx, i) {
                  final user = _contacts[i];
                  final isSelected = _selectedIds.contains(user['id']);
                  return CheckboxListTile(
                    title: Text(user['username']),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                         if(val!) _selectedIds.add(user['id']);
                         else _selectedIds.remove(user['id']);
                      });
                    },
                  );
                },
              ),
            ),
            if(_isLoading) const CircularProgressIndicator()
            else ElevatedButton(
              onPressed: _selectedIds.isEmpty ? null : _createGroup,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }
}
