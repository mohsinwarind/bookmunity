import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../design/brand_logo.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/social/data/social_models.dart';
import '../features/social/data/social_providers.dart';
import '../features/social/presentation/choose_username_screen.dart';
import 'login.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(firebaseReadyProvider)) return const LibraryScreen();
    final user = ref.watch(authUserProvider);
    return user.when(
      loading: () => const BrandLoading(),
      error: (_, _) => const LoginPage(),
      data: (user) => user == null ? const LoginPage() : const _ProfileGate(),
    );
  }
}

/// Every account needs a username before using the app. Accounts made
/// before usernames were part of signup are asked once here. If Firestore
/// cannot be reached the user is let in; social screens handle that case.
class _ProfileGate extends ConsumerWidget {
  const _ProfileGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(signupInProgressProvider)) {
      return const BrandLoading(message: 'Setting up your profile…');
    }
    final status = ref.watch(myProfileStatusProvider).valueOrNull;
    return switch (status) {
      null || ProfileStatus.loading => const BrandLoading(),
      ProfileStatus.missing => ChooseUsernameScreen(
        onSignOut: () => AuthController().logout(),
      ),
      ProfileStatus.ready || ProfileStatus.unavailable => const LibraryScreen(),
    };
  }
}
