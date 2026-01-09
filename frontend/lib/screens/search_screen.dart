import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../config/config.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<dynamic> _results = [];
  final UserService _userService = UserService();

  Future<void> _search() async {
    try {
      final results = await _userService.searchUsers(_controller.text);
      setState(() => _results = results);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _invite(int id) async {
    try {
      await _userService.sendInvite(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite sent!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Search username...', border: InputBorder.none),
            onSubmitted: (_) => _search(),
        ),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: _search)],
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (ctx, i) {
          final user = _results[i];
          return ListTile(
            leading: CircleAvatar(
                 backgroundImage: user['profilePicture'] != null 
                    ? NetworkImage('${Config.baseUrl}/${user['profilePicture']}') 
                    : null,
                 child: user['profilePicture'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user['username']),
            trailing: IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () => _invite(user['id']),
            ),
          );
        },
      ),
    );
  }
}
