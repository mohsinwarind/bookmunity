import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../features/library/presentation/library_screen.dart';
import 'login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AuthController();
    return StreamBuilder<User?>(
      stream: controller.authStateChanges,
      initialData: controller.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == null
            ? const LoginPage()
            : const LibraryScreen();
      },
    );
  }
}
