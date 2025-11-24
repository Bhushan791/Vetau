import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/homeAppBar.dart';
import 'package:frontend/pages/chat/chat_page.dart';
import 'package:frontend/stores/chats_provider.dart';
import 'package:frontend/models/chat_model.dart';


class ChatsPage extends ConsumerStatefulWidget {
  const ChatsPage({super.key});

  @override
  ConsumerState<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends ConsumerState<ChatsPage> {
  @override
  void initState() {
    super.initState();
    // Load chats when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatsProvider.notifier).loadChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
              backgroundColor: Colors.blue,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: HomeAppBar(
            rewardPoints: 120.76,
            onNotificationTap: () {
              print("Notification tapped");
            },
            onProfileTap: () {
              print("Profile tapped");
            },
          ),
        ),
        body: Consumer(
          builder: (context, ref, child) {
            final chats = ref.watch(chatsProvider);
            
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  'No chats available',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(chat.otherParticipant.profileImage),
                    ),
                    title: Text(chat.otherParticipant.fullName),
                    subtitle: Text(
                      chat.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chat.itemName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          chat.postType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: chat.postType == 'lost' ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/chat_details',
                        arguments: chat.chatId,
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      ),
    );
  }
}