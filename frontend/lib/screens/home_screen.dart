import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'invites_screen.dart';
import 'create_group_screen.dart';
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
  bool _isSelectedChatGroup = false;
  bool _isCrashing = false;

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
    if (_isCrashing) {
      throw FlutterError('Simulated UI crash for demonstration');
    }
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
                    isGroup: _isSelectedChatGroup,
                  ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);

    return AppBar(
      title: const Text('Kood/Sisu Messenger'),
      bottom: isMobile
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
          icon: const Icon(Icons.bug_report, color: Colors.orangeAccent),
          tooltip: 'Test UI Crash',
          onPressed: () {
            debugPrint('Simulating UI Crash via State...');
            setState(() {
              _isCrashing = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          tooltip: 'Test Async Error',
          onPressed: () {
            debugPrint('Simulating Async Error...');
            // Manually trigger the error handler for immediate feedback
            final error = 'Simulated asynchronous exception for demonstration';
            PlatformDispatcher.instance.onError!(error, StackTrace.current);
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Sync',
          onPressed: () {
            chat.updatePendingInvitesCount();
            chat.loadChats();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Syncing...'), duration: Duration(seconds: 1)));
          },
        ),
        if (!isMobile) ...[
          // Exposed buttons for Desktop
          _buildInviteButton(context),
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'New Group',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
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
            onPressed: () {
               showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        auth.logout();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ] else ...[
          // Popup Menu for Mobile to avoid overflow
          _buildInviteButton(context),
          IconButton(
            icon: const Icon(Icons.person_search),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'group') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen()));
              } else if (value == 'profile') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              } else if (value == 'logout') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          auth.logout();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'group',
                child: ListTile(
                  leading: Icon(Icons.group_add),
                  title: const Text('New Group'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: const Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
                  title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInviteButton(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, chat, __) => Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () async {
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const InvitesScreen()));
              
              if (result != null && result is Map && mounted) {
                final int chatId = result['id'];
                final String title = result['title'];
                final bool isGroup = result['isGroup'] ?? false;
                
                if (ResponsiveLayout.isMobile(context)) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => 
                    ChatScreen(chatId: chatId, title: title, isGroup: isGroup)));
                } else {
                  setState(() {
                    _selectedChatId = chatId;
                    _activeTitle = title;
                    _isSelectedChatGroup = isGroup;
                  });
                }
              }
            },
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
            final chatName = chat['isGroup'] == true ? (chat['name'] ?? 'Group') : (displayUser['username'] ?? 'Chat');
            
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
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: (chat['isGroup'] == true || displayUser['profilePicture'] == null)
                          ? const AssetImage('assets/images/defaultProfile.jpg') as ImageProvider
                          : NetworkImage('${Config.baseUrl}/${displayUser['profilePicture']}'),
                    ),
                    if (chat['isGroup'] == true)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.deepPurpleAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.group, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                title: Text(chatName),
                subtitle: Text(
                  chat['lastMessage'] != null 
                    ? chat['lastMessage'].toString() 
                    : (chat['lastMessageAt'] != null ? 'Last active: ${chat['lastMessageAt'].toString().substring(0, 16).replaceAll('T', ' ')}' : 'No messages'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (chat['lastMessageAt'] != null)
                      Text(
                        chat['lastMessageAt'].toString().substring(11, 16),
                        style: const TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                    const SizedBox(height: 4),
                    if (!isArchivedList && chat['unreadCount'] != null && chat['unreadCount'] > 0) 
                       Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(color: Colors.deepPurpleAccent, borderRadius: BorderRadius.circular(10)),
                           child: Text('${chat['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                       )
                  ],
                ),
                onTap: () {
                  if (ResponsiveLayout.isMobile(context)) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ChatScreen(
                                chatId: chat['id'],
                                title: chatName,
                                isGroup: chat['isGroup'] == true)));
                  } else {
                    setState(() {
                      _selectedChatId = chat['id'];
                      _activeTitle = chatName;
                      _isSelectedChatGroup = chat['isGroup'] == true;
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
