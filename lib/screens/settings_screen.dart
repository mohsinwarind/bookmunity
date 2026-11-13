import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../design/brutal_theme.dart';
import '../design/brutal_widgets.dart';
import '../features/reader/presentation/widgets/reader_settings_sheet.dart';
import '../features/social/data/social_providers.dart';
import '../features/social/presentation/friends_screen.dart';
import '../providers/app_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authUserProvider).valueOrNull;
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final themeMode = ref.watch(appThemeModeProvider);
    final reader = ref.watch(settingsProvider);
    final shareActivity = ref.watch(shareActivityProvider);

    return Scaffold(
      appBar: const BrutalAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          BrutalCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: BrutalColors.blue,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ??
                            (user?.displayName?.isNotEmpty == true
                                ? user!.displayName!
                                : 'Reader'),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        [
                          if (profile != null) '@${profile.username}',
                          if (user?.email != null) user!.email!,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Appearance'),
          SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Dark'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (value) =>
                ref.read(appThemeModeProvider.notifier).set(value.first),
          ),
          const SizedBox(height: 24),
          const SectionLabel('Reading'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.text_fields),
            title: const Text('Text, page colour and layout'),
            subtitle: Text(
              '${reader.fontSize.round()} pt · '
              '${reader.flow == ReaderFlow.paginated ? 'Pages' : 'Scroll'} · '
              '${reader.theme.name[0].toUpperCase()}${reader.theme.name.substring(1)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showReaderSettingsSheet(context),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Friends and privacy'),
          if (profile == null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.alternate_email),
              title: const Text('Choose a username'),
              subtitle: const Text('Needed for friends and reviews'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendsScreen()),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.share_outlined),
            title: const Text('Share reading activity with friends'),
            subtitle: const Text(
              'Books you start and finish, badges and reviews',
            ),
            value: shareActivity,
            onChanged: (value) =>
                ref.read(shareActivityProvider.notifier).set(value),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Library'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh all book details'),
            subtitle: const Text(
              'Re-read titles, authors, covers and genres from your files',
            ),
            onTap: () => _refreshAll(context, ref),
          ),
          const SizedBox(height: 24),
          BrutalPressable(
            onPressed: () => _logout(context),
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: BrutalColors.red,
            child: const Center(child: Text('Log out')),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = await ref.read(importServiceProvider.future);
      final count = await service.refreshAllMetadata();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Refreshed $count book${count == 1 ? '' : 's'}.'),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Refresh failed: $error')));
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your books, highlights and badges stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthController().logout();
    if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
