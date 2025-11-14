import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/pages/detail_home.dart';
import 'package:frontend/pages/forgotPassword.dart';

// pages
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/login.dart';
import 'package:frontend/pages/profile.dart';
import 'package:frontend/pages/register.dart';
import 'package:frontend/pages/search.dart';
import 'package:frontend/pages/chats.dart';
import 'package:frontend/pages/more.dart';
import 'package:frontend/pages/post.dart';
import 'package:frontend/pages/startPage.dart';

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
      initialRoute: '/',

      // ✅ Route definitions
      routes: {
        '/': (context) => const StartPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/search': (context) => const SearchPage(),
        '/chats': (context) => const ChatsPage(),
        '/more': (context) => const MorePage(),
        '/post': (context) => const PostPage(),
        '/detailHome': (context) => const DetailHome(),
        '/profile': (context) => const ProfilePage(),
        '/forgotPassword': (context) => const ForgotPage(),
      },
    );
  }
}