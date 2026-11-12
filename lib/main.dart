import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'design/brutal_theme.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  runApp(const ProviderScope(child: BookmunityApp()));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // Firebase options are not configured for Linux yet.
  }
}

class BookmunityApp extends StatelessWidget {
  const BookmunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookmunity',
      theme: brutalTheme(dark: false),
      home: const AuthGate(),
    );
  }
}
