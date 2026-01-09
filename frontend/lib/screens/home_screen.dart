import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'invites_screen.dart';
import 'new_group_screen.dart';
import '../config/config.dart';
import '../services/data_service.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ChatProvider? _chatProvider;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to trigger init safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if(!mounted) return;
       final chatProvider = Provider.of<ChatProvider>(context, listen: false);
       final authProvider = Provider.of<AuthProvider>(context, listen: false);
       
       if(authProvider.token != null && authProvider.user != null) {
          try {
            chatProvider.initSocket(authProvider.token!, authProvider.user!['id']);
            chatProvider.updatePendingInvitesCount();
            chatProvider.loadChats();
          } catch (e) {
            if (e is UnauthorizedException) {
              authProvider.logout();
            }
          }
       }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture provider reference for safe disposal
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _chatProvider?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kood/Messenger'),
        actions: [
          Consumer<ChatProvider>(
            builder: (_, chat, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitesScreen())),
                ),
                if(chat.pendingInvites > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${chat.pendingInvites}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
          ),
           IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'New Group',
            onPressed: () => Navigator.pushNamed(context, NewGroupScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (ctx, chatData, _) => ListView.builder(
          itemCount: chatData.chats.length,
          itemBuilder: (ctx, i) {
            final chat = chatData.chats[i];
            final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
            final userId = currentUser?['id'];
            
            String title;
            dynamic profilePic;
            
            if (chat['isGroup'] == true) {
              title = chat['name'] ?? 'Group Chat';
              profilePic = null; // Maybe a group icon later
            } else {
              final otherUser = chat['Users'].firstWhere((u) => u['id'] != userId, orElse: () => chat['Users'][0]);
              title = otherUser['username'];
              profilePic = otherUser['profilePicture'];
            }
            
            return Dismissible(
              key: Key(chat['id'].toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.archive, color: Colors.white),
              ),
              onDismissed: (direction) {
                chatData.archiveChat(chat['id']);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat archived')));
              },
              child: ListTile(
                leading: CircleAvatar(
                   backgroundImage: profilePic != null 
                      ? NetworkImage('${Config.baseUrl}/$profilePic') 
                      : null,
                   child: profilePic == null 
                      ? Icon(chat['isGroup'] == true ? Icons.group : Icons.person) 
                      : null,
                ),
                title: Text(title),
                subtitle: Text(chat['lastMessageAt'] ?? 'No messages'),
                trailing:  (chat['unreadCount'] != null && chat['unreadCount'] > 0) 
                   ? Container(
                       padding: const EdgeInsets.all(8),
                       decoration: const BoxDecoration(
                         color: Colors.deepPurpleAccent,
                         shape: BoxShape.circle,
                       ),
                       child: Text(
                         '${chat['unreadCount']}',
                         style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                       ),
                     )
                   : null,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                      ChatScreen(chatId: chat['id'], title: title)));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
