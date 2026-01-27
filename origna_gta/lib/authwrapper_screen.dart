import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/login_screen.dart';
import 'package:origna_gta/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)))),
          );
        }

        // User is logged in
        if (snapshot.hasData) {
          return const MainScreen();
        }

        // User is not logged in - show HomeScreen directly but with limited functionality
        // We'll modify MainScreen to handle null user
        return const MainScreen();
      },
    );
  }
}