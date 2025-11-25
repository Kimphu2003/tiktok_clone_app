import 'package:flutter/material.dart';

import '../../constants.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(Duration.zero), // Just to wait one frame
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = firebaseAuth.currentUser;
        if (user != null) {
          return const HomeScreen();
        } else {
          return LoginScreen();
        }
      },
    );
  }
}