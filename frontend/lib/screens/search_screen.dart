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
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    try {
      debugPrint('SearchScreen: Searching for "$query"');
      final results = await _userService.searchUsers(query);
      debugPrint('SearchScreen: Found ${results.length} results');
      setState(() => _results = results);
      if (results.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No users found')),
        );
      }
    } catch (e) {
      debugPrint('SearchScreen: Search error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.redAccent),
      );
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: const Text('Search Users', style: TextStyle(color: Colors.white, fontSize: 18)),
              background: Container(color: Colors.deepPurpleAccent),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type username...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _search,
                  ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _search(),
              ),
            ),
          ),
          if (_results.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Start searching for new connections!')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final user = _results[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profilePicture'] != null
                            ? NetworkImage('${Config.baseUrl}/${user['profilePicture']}')
                            : const AssetImage('assets/images/defaultProfile.jpg') as ImageProvider,
                      ),
                      title: Text(user['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('New Messenger User'),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.deepPurpleAccent),
                        onPressed: () => _invite(user['id']),
                      ),
                    ),
                  );
                },
                childCount: _results.length,
              ),
            ),
        ],
      ),
    );
  }
}
