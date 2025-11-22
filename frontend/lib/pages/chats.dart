import 'package:flutter/material.dart';
import 'package:frontend/components/bottomNav.dart';
import 'package:frontend/components/homeAppBar.dart';
import 'package:frontend/services/chat_service.dart';
import 'package:frontend/models/chat_model.dart';
import 'package:frontend/pages/chat_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  List<ChatModel> chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  Future<void> fetchChats() async {
    try {
      final fetchedChats = await ChatService.getChats(context);
      setState(() {
        chats = fetchedChats;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching chats: $e');
      setState(() {
        isLoading = false;
      });
    }
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : chats.isEmpty
                ? const Center(
                    child: Text(
                      'No chats available',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                : ListView.builder(
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatPage(chat: chat),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
        bottomNavigationBar: const BottomNav(currentIndex: 3),
      ),
    );
  }
}