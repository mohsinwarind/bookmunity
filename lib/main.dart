import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_messenger.dart';
import 'firebase_options.dart';
import 'design/brutal_theme.dart';
import 'features/achievements/data/achievement_service.dart';
import 'features/social/data/social_providers.dart';
import 'providers/settings_providers.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  runApp(
    ProviderScope(
      overrides: appProviderOverrides,
      child: const BookmunityApp(),
    ),
  );
}

/// Connects modules that must not import each other directly.
final appProviderOverrides = [
  badgeUnlockListenersProvider.overrideWith(socialBadgeListeners),
];

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // Firebase options are not configured for Linux yet.
  }
}

class BookmunityApp extends ConsumerWidget {
  const BookmunityApp({this.home = const AuthGate(), super.key});

  final Widget home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bookmunity',
      scaffoldMessengerKey: appMessengerKey,
      theme: brutalTheme(dark: false),
      darkTheme: brutalTheme(dark: true),
      themeMode: ref.watch(appThemeModeProvider),
      home: home,
    );
  }
}
