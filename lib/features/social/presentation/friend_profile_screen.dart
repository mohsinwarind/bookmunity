import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../design/formatters.dart';
import '../data/social_models.dart';
import '../data/social_providers.dart';
import 'friends_screen.dart';
import 'my_profile_screen.dart';
import 'user_avatar.dart';

/// Public profile of any reader. Friends also see recent activity (the
/// rules only let friends read it); others get an "Add friend" action.
class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(myProfileProvider).valueOrNull;
    if (me != null && me.uid == uid) return const MyProfileScreen();

    final profile = ref.watch(profileProvider(uid));
    final friends = ref.watch(friendsProvider).valueOrNull ?? const <Friend>[];
    final isFriend = friends.any((friend) => friend.uid == uid);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: BrutalAppBar(
        title: profile.valueOrNull?.displayName ?? 'Reader',
        actions: [
          if (isFriend)
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
              ProfileHeader(profile: value),
              const SizedBox(height: 16),
              if (!isFriend && me != null) ...[
                _FriendAction(me: me, other: value),
                const SizedBox(height: 16),
              ],
              ProfileStatsRow(profile: value),
              const SizedBox(height: 24),
              const SectionLabel('Recent activity'),
              if (isFriend)
                _Activity(uid: uid, name: value.displayName)
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Become friends with ${value.displayName} to see what '
                    'they are reading.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _unfriend(BuildContext context, WidgetRef ref) async {
    final name =
        ref.read(profileProvider(uid)).valueOrNull?.displayName ??
        'this friend';
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
    try {
      await ref.read(socialRepositoryProvider)!.removeFriend(uid);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(socialErrorMessage(error))),
      );
    }
  }
}

class _Activity extends ConsumerWidget {
  const _Activity({required this.uid, required this.name});

  final String uid;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return ref
        .watch(friendActivityProvider(uid))
        .when(
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
                      ActivityTile(activity: item, name: name),
                  ],
                ),
        );
  }
}

/// Add / pending / accept, depending on the request state between us.
class _FriendAction extends ConsumerWidget {
  const _FriendAction({required this.me, required this.other});

  final Profile me;
  final Profile other;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoing =
        ref.watch(outgoingRequestsProvider).valueOrNull ??
        const <FriendRequest>[];
    final incoming =
        ref.watch(incomingRequestsProvider).valueOrNull ??
        const <FriendRequest>[];
    final sent = outgoing.where((r) => r.toUid == other.uid).firstOrNull;
    final received = incoming.where((r) => r.fromUid == other.uid).firstOrNull;
    final repository = ref.watch(socialRepositoryProvider)!;

    Future<void> run(Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text(socialErrorMessage(error))),
        );
      }
    }

    if (received != null) {
      return BrutalPressable(
        onPressed: () => run(() => repository.acceptRequest(received, me: me)),
        backgroundColor: BrutalColors.green,
        child: const Center(child: Text('Accept friend request')),
      );
    }
    if (sent != null) {
      return OutlinedButton.icon(
        onPressed: () => run(() => repository.deleteRequest(sent)),
        icon: const Icon(Icons.hourglass_top, size: 18),
        label: const Text('Request sent · tap to cancel'),
      );
    }
    return BrutalPressable(
      onPressed: () => run(() => repository.sendRequest(me: me, to: other)),
      backgroundColor: BrutalColors.blue,
      foregroundColor: Colors.white,
      child: const Center(child: Text('Add friend')),
    );
  }
}

/// Avatar, names, bio and join date. Shared with [MyProfileScreen].
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.profile, this.avatar, super.key});

  final Profile profile;

  /// Replaces the plain avatar (the own-profile screen adds an edit badge).
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        avatar ??
            UserAvatar(uid: profile.uid, hasPhoto: profile.hasPhoto, size: 96),
        const SizedBox(height: 12),
        Text(
          profile.displayName,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text('@${profile.username}', style: theme.textTheme.bodySmall),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            profile.bio,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
        if (profile.createdAt != null) ...[
          const SizedBox(height: 6),
          Text(
            'Reading on Bookmunity since ${formatDate(profile.createdAt!)}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({required this.profile, super.key});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Stat(label: 'Books finished', value: profile.booksFinished),
        const SizedBox(width: 10),
        _Stat(label: 'Day streak', value: profile.currentStreak),
        const SizedBox(width: 10),
        _Stat(label: 'Badges', value: profile.badgeCount),
      ],
    );
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
