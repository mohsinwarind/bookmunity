import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../data/social_providers.dart';
import '../data/social_repository.dart';
import 'cute_avatar.dart';
import 'username_field.dart';

/// Asks a signed-in user without a profile to claim a username. Shown by
/// the startup gate (accounts created before usernames were part of
/// signup, or when signup could not save it) and by the Friends tab.
class ChooseUsernameScreen extends ConsumerStatefulWidget {
  const ChooseUsernameScreen({this.onSignOut, super.key});

  /// Shown as a "Sign out" action when provided (startup gate only).
  final VoidCallback? onSignOut;

  @override
  ConsumerState<ChooseUsernameScreen> createState() =>
      _ChooseUsernameScreenState();
}

class _ChooseUsernameScreenState extends ConsumerState<ChooseUsernameScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _checker = UsernameChecker();
  late final _displayName = TextEditingController(
    text: ref.read(authUserProvider).valueOrNull?.displayName ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _checker.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repository = ref.read(socialRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (await _checker.checkNow(_username.text) == false) return;
      ProfileStats stats;
      try {
        stats = await ref.read(socialActivityProvider).currentStats();
      } catch (_) {
        stats = ProfileStats.zero;
      }
      await repository.createProfile(
        username: _username.text,
        displayName: _displayName.text,
        stats: stats,
      );
    } catch (error) {
      if (mounted) setState(() => _error = socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = ref.watch(authUserProvider).valueOrNull?.uid ?? '';
    return Scaffold(
      appBar: BrutalAppBar(
        title: 'Your profile',
        actions: [
          if (widget.onSignOut != null)
            TextButton(
              onPressed: widget.onSignOut,
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(child: CuteAvatar(seed: uid, size: 96)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Your avatar — you can add a photo later.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 20),
                BrutalCard(
                  backgroundColor: BrutalColors.pink,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick a username',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: BrutalColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Friends find you by your username. They see the books '
                        'you start and finish, your badges and your reviews. '
                        'Your email is never shared.',
                        style: TextStyle(color: BrutalColors.ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      UsernameField(controller: _username, checker: _checker),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _displayName,
                        maxLength: 50,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                        validator: (value) => (value?.trim().isEmpty ?? true)
                            ? 'Enter the name friends will see.'
                            : null,
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 20),
                BrutalPressable(
                  onPressed: _saving ? null : _save,
                  backgroundColor: BrutalColors.blue,
                  foregroundColor: Colors.white,
                  child: Center(child: Text(_saving ? 'Saving…' : 'Continue')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
