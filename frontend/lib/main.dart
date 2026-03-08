import 'package:bookmind/screens/landing_screen.dart';
import 'package:bookmind/screens/main_layout.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/user_session.dart';

void main() {
  runApp(const BookMindApp());
}

class BookMindApp extends StatelessWidget {
  const BookMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookMind',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      home: const SplashDecider(),
    );
  }
}

class SplashDecider extends StatelessWidget {
  const SplashDecider({super.key});

  Future<bool> _checkLogin() async {
    final userId = await UserSession.getUserId();
    return userId != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const MainLayout();
        } else {
          return const LandingScreen(); // 👈 better UX than Register
        }
      },
    );
  }
}
