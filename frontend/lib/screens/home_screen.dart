import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'invites_screen.dart';
import '../config/config.dart';
import '../widgets/responsive_layout.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  ChatProvider? _chatProvider;
  int? _selectedChatId;
  String? _activeTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Use post-frame callback to trigger init safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if(!mounted) return;
       final chatProvider = Provider.of<ChatProvider>(context, listen: false);
       final authProvider = Provider.of<AuthProvider>(context, listen: false);
       
       if(authProvider.token != null && authProvider.user != null) {
          chatProvider.initSocket(authProvider.token!, authProvider.user!['id']);
          chatProvider.updatePendingInvitesCount();
          chatProvider.loadChats();
       }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
       _chatProvider?.updatePendingInvitesCount();
       _chatProvider?.loadChats();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Capture provider reference for safe disposal
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatProvider?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileLayout: _buildMobileLayout(context),
      desktopLayout: _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: TabBarView(
          children: [
            _buildChatList(context, isArchivedList: false),
            _buildChatList(context, isArchivedList: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          SizedBox(
            width: 350,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Chats'),
                      Tab(text: 'Archived'),
                    ],
                    labelColor: Colors.deepPurpleAccent,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildChatList(context, isArchivedList: false),
                        _buildChatList(context, isArchivedList: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _selectedChatId == null
                ? const Center(child: Text('Select a chat to start messaging'))
                : ChatScreen(
                    key: ValueKey('chat_$_selectedChatId'),
                    chatId: _selectedChatId!,
                    title: _activeTitle ?? 'Chat',
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Kood/Messenger'),
      bottom: ResponsiveLayout.isMobile(context)
          ? const TabBar(
              tabs: [
                Tab(text: 'Chats', icon: Icon(Icons.chat)),
                Tab(text: 'Archived', icon: Icon(Icons.archive)),
              ],
              indicatorColor: Colors.deepPurpleAccent,
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            final chat = Provider.of<ChatProvider>(context, listen: false);
            chat.updatePendingInvitesCount();
            chat.loadChats();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Syncing...'), duration: Duration(seconds: 1)));
          },
        ),
        Consumer<ChatProvider>(
          builder: (_, chat, __) => Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const InvitesScreen())),
              ),
              if (chat.pendingInvites > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${chat.pendingInvites}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center),
                  ),
                )
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.person_search),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SearchScreen())),
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          onPressed: () =>
              Provider.of<AuthProvider>(context, listen: false).logout(),
        ),
      ],
    );
  }

  Widget _buildChatList(BuildContext context, {required bool isArchivedList}) {
    return Consumer<ChatProvider>(
      builder: (ctx, chatData, _) {
        final list = isArchivedList ? chatData.archivedChats : chatData.activeChats;
        
        if(list.isEmpty) {
          return Center(child: Text(isArchivedList ? 'No archived chats' : 'No active chats'));
        }

        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i) {
            final chat = list[i];
            final currentUser = Provider.of<AuthProvider>(context, listen: false).user;
            final userId = currentUser?['id'];
            final otherUser = chat['Users'].firstWhere((u) => u['id'] != userId, orElse: () => chat['Users'][0]);
            final displayUser = otherUser;
            
            return Dismissible(
              key: Key('${isArchivedList?'archived':'active'}_${chat['id']}'),
              // End to Start (Right to Left) -> DELETE
              // Start to End (Left to Right) -> ARCHIVE / UNARCHIVE
              secondaryBackground: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Row(
                   mainAxisAlignment: MainAxisAlignment.end,
                   children: [
                     Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     SizedBox(width: 8),
                     Icon(Icons.delete_forever, color: Colors.white),
                   ],
                ),
              ),
              background: Container(
                color: Colors.orangeAccent,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                   children: [
                     Icon(isArchivedList ? Icons.unarchive : Icons.archive, color: Colors.white),
                     const SizedBox(width: 8),
                     Text(isArchivedList ? 'Unarchive' : 'Archive', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                   ],
                ),
              ),
              confirmDismiss: (direction) async {
                if(direction == DismissDirection.endToStart) {
                   return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Chat'),
                      content: const Text('Are you sure you want to delete this chat? History will be hidden for you until a new message arrives.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Delete for me'),
                        ),
                      ],
                    ),
                  );
                }
                return true; // Auto-confirm Archive
              },
              onDismissed: (direction) {
                if(direction == DismissDirection.endToStart) {
                   chatData.deleteChat(chat['id']);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat deleted locally')));
                } else {
                   if(isArchivedList) {
                      chatData.unarchiveChat(chat['id']);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat unarchived')));
                   } else {
                      chatData.archiveChat(chat['id']);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat archived')));
                   }
                }
              },
              child: ListTile(
                leading: CircleAvatar(
                   backgroundImage: displayUser['profilePicture'] != null 
                      ? NetworkImage('${Config.baseUrl}/${displayUser['profilePicture']}') 
                      : const AssetImage('assets/images/defaultProfile.jpg') as ImageProvider,
                ),
                title: Text(displayUser['username']),
                subtitle: Text(chat['lastMessageAt'] != null ? 'Last active: ${chat['lastMessageAt'].toString().substring(0, 10)}' : 'No messages'),
                trailing:  (!isArchivedList && chat['unreadCount'] != null && chat['unreadCount'] > 0) 
                   ? Container(
                       padding: const EdgeInsets.all(8),
                       decoration: const BoxDecoration(color: Colors.deepPurpleAccent, shape: BoxShape.circle),
                       child: Text('${chat['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                     )
                   : null,
                onTap: () {
                  if (ResponsiveLayout.isMobile(context)) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(
                                chatId: chat['id'],
                                title: displayUser['username'])));
                  } else {
                    setState(() {
                      _selectedChatId = chat['id'];
                      _activeTitle = displayUser['username'];
                    });
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
