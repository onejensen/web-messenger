import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/data_service.dart';
import '../config/config.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final List<dynamic> _selectedUsers = [];
  bool _isLoadingUsers = false;
  bool _isCreating = false;
  List<dynamic> _availableUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      // For simplicity, we'll use a search with empty query to get some users? 
      // Actually, let's use the existing users from the chat provider's chats.
      // Or search for 'a' to get some results. 
      // Better: The user should search for users to add.
      // For now, let's just show a search bar.
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _availableUsers = []);
      return;
    }
    final userService = UserService();
    try {
      final results = await userService.searchUsers(query);
      setState(() {
        _availableUsers = results;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
  }

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a group name')));
      return;
    }
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one participant')));
      return;
    }

    setState(() => _isCreating = true);
    try {
      final chatService = ChatService();
      final userIds = _selectedUsers.map((u) => u['id'] as int).toList();
      await chatService.createGroupChat(_nameController.text, userIds);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created and invitations sent')));
        context.read<ChatProvider>().loadChats();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          if (_isCreating)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          else
            TextButton(
              onPressed: _createGroup,
              child: const Text('CREATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group name',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const Divider(),
          if (_selectedUsers.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(alignment: Alignment.centerLeft, child: Text('Selected participants:', style: TextStyle(fontWeight: FontWeight.bold))),
            ),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: user['profilePicture'] != null 
                            ? NetworkImage(user['profilePicture'].startsWith('http') ? user['profilePicture'] : '${Config.baseUrl}/${user['profilePicture']}')
                            : null,
                          child: user['profilePicture'] == null ? const Icon(Icons.person) : null,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedUsers.removeAt(index)),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
          ],
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _searchUsers,
              decoration: const InputDecoration(
                hintText: 'Search participants...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _availableUsers.length,
              itemBuilder: (context, index) {
                final user = _availableUsers[index];
                final isSelected = _selectedUsers.any((u) => u['id'] == user['id']);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profilePicture'] != null 
                        ? NetworkImage(user['profilePicture'].startsWith('http') ? user['profilePicture'] : '${Config.baseUrl}/${user['profilePicture']}')
                        : null,
                    child: user['profilePicture'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['username']),
                  subtitle: Text(user['email']),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (!isSelected) _selectedUsers.add(user);
                        } else {
                          _selectedUsers.removeWhere((u) => u['id'] == user['id']);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedUsers.removeWhere((u) => u['id'] == user['id']);
                      } else {
                        _selectedUsers.add(user);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
