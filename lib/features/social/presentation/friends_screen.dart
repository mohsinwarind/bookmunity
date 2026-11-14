import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../design/formatters.dart';
import '../data/social_models.dart';
import '../data/social_providers.dart';
import '../data/social_repository.dart';
import 'friend_profile_screen.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(socialRepositoryProvider) == null) {
      return Scaffold(
        appBar: const BrutalAppBar(title: 'Friends'),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Sign in to use friends',
          message: ref.watch(firebaseReadyProvider)
              ? 'Friends, activity and reviews need a Bookmunity account.'
              : 'Friends are not available on this platform.',
        ),
      );
    }
    final profile = ref.watch(myProfileProvider);
    return profile.when(
      loading: () => const Scaffold(
        appBar: BrutalAppBar(title: 'Friends'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: const BrutalAppBar(title: 'Friends'),
        body: EmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Friends are unavailable',
          message: socialErrorMessage(error),
        ),
      ),
      data: (me) => me == null ? const _ChooseUsername() : _FriendsHome(me: me),
    );
  }
}

// ------------------------------------------------------------ onboarding

class _ChooseUsername extends ConsumerStatefulWidget {
  const _ChooseUsername();

  @override
  ConsumerState<_ChooseUsername> createState() => _ChooseUsernameState();
}

class _ChooseUsernameState extends ConsumerState<_ChooseUsername> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  late final _displayName = TextEditingController(
    text: ref.read(authUserProvider).valueOrNull?.displayName ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
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
    return Scaffold(
      appBar: const BrutalAppBar(title: 'Friends'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          BrutalCard(
            backgroundColor: BrutalColors.pink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Read with friends',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: BrutalColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick a username so friends can find you. Friends see the '
                  'books you start and finish, your badges and your reviews. '
                  'Your email is never shared.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _username,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixText: '@',
                    helperText: '3–20 letters, numbers or underscores',
                  ),
                  validator: Usernames.validate,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayName,
                  maxLength: 50,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Display name'),
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
            child: Center(
              child: Text(_saving ? 'Saving…' : 'Create my profile'),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ home

class _FriendsHome extends ConsumerWidget {
  const _FriendsHome({required this.me});

  final Profile me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: BrutalAppBar(
          title: 'Friends',
          actions: [
            IconButton(
              tooltip: 'Add a friend',
              icon: const Icon(Icons.person_add_alt),
              onPressed: () => _showSearch(context, me),
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Activity'),
              const Tab(text: 'Friends'),
              Tab(
                child: Badge(
                  isLabelVisible: incoming.isNotEmpty,
                  label: Text('${incoming.length}'),
                  child: const Text('Requests'),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _FeedTab(),
            _FriendsTab(me: me),
            _RequestsTab(me: me),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(friendFeedProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(friendFeedProvider.future),
      child: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          children: [
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Activity could not be loaded',
              message: socialErrorMessage(error),
            ),
          ],
        ),
        data: (items) => items.isEmpty
            ? ListView(
                children: const [
                  EmptyState(
                    icon: Icons.dynamic_feed_outlined,
                    title: 'Nothing here yet',
                    message:
                        'When your friends start or finish books, earn badges '
                        'or write reviews, it shows up here.',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const Divider(indent: 72, endIndent: 16),
                itemBuilder: (context, index) => ActivityTile(
                  activity: items[index],
                  name: _nameFor(ref, items[index].ownerUid),
                ),
              ),
      ),
    );
  }

  String _nameFor(WidgetRef ref, String uid) {
    final friends = ref.watch(friendsProvider).valueOrNull ?? const [];
    for (final friend in friends) {
      if (friend.uid == uid) return friend.displayName;
    }
    return 'A friend';
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({required this.activity, required this.name, super.key});

  final Activity activity;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, text) = switch (activity.type) {
      ActivityType.started => (
        Icons.menu_book_outlined,
        BrutalColors.blue,
        'started reading ${activity.title}',
      ),
      ActivityType.finished => (
        Icons.check_circle_outline,
        BrutalColors.green,
        'finished ${activity.title}',
      ),
      ActivityType.badge => (
        Icons.emoji_events_outlined,
        BrutalColors.yellow,
        'earned the ${activity.badgeTitle} badge',
      ),
      ActivityType.review => (
        Icons.star_outline,
        BrutalColors.pink,
        'rated ${activity.title} ${'★' * activity.rating}',
      ),
    };
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: BrutalColors.ink),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' $text'),
          ],
        ),
      ),
      subtitle: Text(
        [
          if (activity.author.isNotEmpty &&
              activity.type != ActivityType.badge)
            activity.author,
          if (activity.createdAt != null) formatDate(activity.createdAt!),
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _FriendsTab extends ConsumerWidget {
  const _FriendsTab({required this.me});

  final Profile me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    return friends.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Friends could not be loaded',
        message: socialErrorMessage(error),
      ),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.people_outline,
              title: 'No friends yet',
              message: 'You are @${me.username}. Search for a friend’s username to connect.',
              action: BrutalPressable(
                onPressed: () => _showSearch(context, me),
                child: const Text('Find friends'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final friend = items[index];
                return ListTile(
                  leading: _Avatar(name: friend.displayName),
                  title: Text(friend.displayName),
                  subtitle: Text('@${friend.username}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FriendProfileScreen(uid: friend.uid),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab({required this.me});

  final Profile me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref.watch(incomingRequestsProvider).valueOrNull ?? const [];
    final outgoing = ref.watch(outgoingRequestsProvider).valueOrNull ?? const [];
    final repository = ref.watch(socialRepositoryProvider)!;
    if (incoming.isEmpty && outgoing.isEmpty) {
      return const EmptyState(
        icon: Icons.mark_email_unread_outlined,
        title: 'No pending requests',
      );
    }
    Future<void> run(BuildContext context, Future<void> Function() action) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await action();
      } catch (error) {
        messenger.showSnackBar(
          SnackBar(content: Text(socialErrorMessage(error))),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (incoming.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SectionLabel('Received'),
          ),
          for (final request in incoming)
            ListTile(
              leading: _Avatar(name: request.fromDisplayName),
              title: Text(request.fromDisplayName),
              subtitle: Text('@${request.fromUsername}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Decline',
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        run(context, () => repository.deleteRequest(request)),
                  ),
                  IconButton.filled(
                    tooltip: 'Accept',
                    style: IconButton.styleFrom(
                      backgroundColor: BrutalColors.green,
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    onPressed: () => run(
                      context,
                      () => repository.acceptRequest(request, me: me),
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (outgoing.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SectionLabel('Sent'),
          ),
          for (final request in outgoing)
            ListTile(
              leading: _Avatar(name: request.toDisplayName),
              title: Text(request.toDisplayName),
              subtitle: Text('@${request.toUsername} · waiting'),
              trailing: TextButton(
                onPressed: () =>
                    run(context, () => repository.deleteRequest(request)),
                child: const Text('Cancel'),
              ),
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- search

void _showSearch(BuildContext context, Profile me) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: _UserSearch(me: me),
      ),
    ),
  );
}

class _UserSearch extends ConsumerStatefulWidget {
  const _UserSearch({required this.me});

  final Profile me;

  @override
  ConsumerState<_UserSearch> createState() => _UserSearchState();
}

class _UserSearchState extends ConsumerState<_UserSearch> {
  List<Profile> _results = const [];
  bool _searching = false;
  String? _error;
  String _query = '';

  Future<void> _search(String value) async {
    final query = value.trim();
    setState(() => _query = query);
    if (query.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await ref.read(socialRepositoryProvider)!.searchUsers(
        query,
      );
      if (mounted && query == _query) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = socialErrorMessage(error));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = {
      for (final friend in ref.watch(friendsProvider).valueOrNull ?? const <Friend>[])
        friend.uid,
    };
    final sent = {
      for (final request
          in ref.watch(outgoingRequestsProvider).valueOrNull ??
              const <FriendRequest>[])
        request.toUid,
    };
    final received = {
      for (final request
          in ref.watch(incomingRequestsProvider).valueOrNull ??
              const <FriendRequest>[])
        request.fromUid,
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            autocorrect: false,
            onChanged: _search,
            decoration: const InputDecoration(
              hintText: 'Search by username',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
        ),
        if (_searching) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!),
          ),
        Expanded(
          child: _query.isNotEmpty && !_searching && _results.isEmpty
              ? const EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'No one found',
                  message: 'Check the spelling of the username.',
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final profile = _results[index];
                    final Widget trailing;
                    if (friends.contains(profile.uid)) {
                      trailing = const Text('Friends');
                    } else if (sent.contains(profile.uid)) {
                      trailing = const Text('Requested');
                    } else if (received.contains(profile.uid)) {
                      trailing = const Text('Wants to connect');
                    } else {
                      trailing = TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(socialRepositoryProvider)!
                                .sendRequest(me: widget.me, to: profile);
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(socialErrorMessage(error)),
                              ),
                            );
                          }
                        },
                        child: const Text('Add'),
                      );
                    }
                    return ListTile(
                      leading: _Avatar(name: profile.displayName),
                      title: Text(profile.displayName),
                      subtitle: Text('@${profile.username}'),
                      trailing: trailing,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      backgroundColor:
          BrutalColors.accents[initial.codeUnitAt(0) % BrutalColors.accents.length],
      foregroundColor: BrutalColors.ink,
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
