import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/config/auth_link_handler.dart';
import 'package:frontend/pages/chat/chat_page.dart';
import 'package:frontend/pages/editProfile.dart';

// Pages
import 'package:frontend/pages/startPage.dart';
import 'package:frontend/pages/login.dart';
import 'package:frontend/pages/register.dart';
import 'package:frontend/pages/home.dart';
import 'package:frontend/pages/search.dart';
import 'package:frontend/pages/chats.dart';
import 'package:frontend/pages/more.dart';
import 'package:frontend/pages/post.dart';
import 'package:frontend/pages/detail_home.dart';
import 'package:frontend/pages/profile.dart';
import 'package:frontend/pages/forgotPassword.dart';

// GLOBAL NAVIGATOR KEY
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize deep-link listener BEFORE running app
  await AuthLinkHandler.init(() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  });

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      initialRoute: '/login',

      // STATIC ROUTES
      routes: {
        '/': (context) => const StartPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/search': (context) => const SearchPage(),
        '/chats': (context) => const ChatsPage(),
        '/more': (context) => const MorePage(),
        '/post': (context) => const PostPage(),
        '/profile': (context) => const ProfilePage(),
        '/forgotPassword': (context) => const ForgotPassword(),
        '/editProfile': (context) => const Editprofile(),
        '/messages': (context) => ChatPage(
              conversationId: ModalRoute.of(context)!.settings.arguments
                  as String, // Pass conversationId as argument
              myId: 'currentUserId', // Replace with actual current user ID
            ),
      },

      // 🚀 DYNAMIC ROUTES (for postId)
      onGenerateRoute: (settings) {
        // For opening detail page with postId
        if (settings.name == '/detailHome') {
          final String postId = settings.arguments as String;

          return MaterialPageRoute(
            builder: (_) => DetailHome(postId: postId),
          );
        }

        // default fallback route
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );
      },
    );
  }
}
