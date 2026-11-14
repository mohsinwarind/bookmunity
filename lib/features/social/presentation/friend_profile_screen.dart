import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../design/formatters.dart';
import '../data/social_providers.dart';
import 'friends_screen.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider(uid));
    final activity = ref.watch(friendActivityProvider(uid));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: BrutalAppBar(
        title: profile.valueOrNull?.displayName ?? 'Friend',
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => _unfriend(context, ref),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove friend')),
            ],
          ),
        ],
      ),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Profile unavailable',
          message: socialErrorMessage(error),
        ),
        data: (value) {
          if (value == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'This profile no longer exists',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: BrutalColors.yellow,
                    foregroundColor: BrutalColors.ink,
                    child: Text(
                      value.displayName.isEmpty
                          ? '?'
                          : value.displayName[0].toUpperCase(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: BrutalColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value.displayName, style: theme.textTheme.titleLarge),
                        Text('@${value.username}', style: theme.textTheme.bodySmall),
                        if (value.createdAt != null)
                          Text(
                            'Reading on Bookmunity since ${formatDate(value.createdAt!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _Stat(label: 'Books finished', value: value.booksFinished),
                  const SizedBox(width: 10),
                  _Stat(label: 'Day streak', value: value.currentStreak),
                  const SizedBox(width: 10),
                  _Stat(label: 'Badges', value: value.badgeCount),
                ],
              ),
              const SizedBox(height: 24),
              const SectionLabel('Recent activity'),
              activity.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Text(socialErrorMessage(error)),
                data: (items) => items.isEmpty
                    ? Text(
                        'No shared activity yet.',
                        style: theme.textTheme.bodySmall,
                      )
                    : Column(
                        children: [
                          for (final item in items)
                            ActivityTile(activity: item, name: value.displayName),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _unfriend(BuildContext context, WidgetRef ref) async {
    final name = ref.read(profileProvider(uid)).valueOrNull?.displayName ?? 'this friend';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $name?'),
        content: const Text(
          'You will no longer see each other’s activity. You can send a new '
          'request later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(socialRepositoryProvider)!.removeFriend(uid);
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(socialErrorMessage(error))));
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: BrutalCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text('$value', style: theme.textTheme.titleLarge),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
