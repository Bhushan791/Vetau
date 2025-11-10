import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/homeAppBar.dart';
import 'package:frontend/pages/app.dart';
import 'package:frontend/pages/home.dart';
void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Riverpod Counter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       debugShowCheckedModeBanner: false,
//       home: const HomePage(),
//     );
//   }
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.blue,
        appBar: PreferredSize(preferredSize: const Size.fromHeight(200), child: HomeAppBar(
          rewardPoints: 120.76,
          onNotificationTap: () {
            print("Notification tapped");
          },
          onProfileTap: () {
            print("Profile tapped");
          },
        ),
        ),
        body: Center(
          child: Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(20)
            ),
            padding: EdgeInsets.all(25),
            child: Icon(Icons.favorite_outline, color: Colors.white, size: 100),
            ),
        ),
      )
    );
  }
}

