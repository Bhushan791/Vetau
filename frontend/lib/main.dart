import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/detail_home.dart';

// pages
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/search.dart';
import 'package:frontend/pages/chats.dart';
import 'package:frontend/pages/more.dart';
import 'package:frontend/pages/post.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ Starting page
      initialRoute: '/home',

      // ✅ Route definitions
      routes: {
        '/home': (context) => const HomePage(),
        '/search': (context) => const SearchPage(),
        '/chats': (context) => const ChatsPage(),
        '/more': (context) => const MorePage(),
        '/post': (context) => const PostPage(),
        '/detailHome': (context) => const DetailHome(),
      },
    );
  }
}
