import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/app_database.dart';
import '../../achievements/data/achievement_service.dart';
import '../../achievements/domain/badges.dart';
import 'social_models.dart';
import 'social_repository.dart';

/// False on platforms where Firebase is not configured (e.g. Linux).
final firebaseReadyProvider = Provider<bool>((ref) => Firebase.apps.isNotEmpty);

final authUserProvider = StreamProvider<User?>((ref) {
  if (!ref.watch(firebaseReadyProvider)) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

final socialRepositoryProvider = Provider<SocialRepository?>((ref) {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return null;
  return SocialRepository(FirebaseFirestore.instance, user.uid);
});

final myProfileProvider = StreamProvider<Profile?>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository?.watchMyProfile() ?? Stream.value(null);
});

final friendsProvider = StreamProvider<List<Friend>>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository?.watchFriends() ?? Stream.value(const []);
});

final incomingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository?.watchIncomingRequests() ?? Stream.value(const []);
});

final outgoingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository?.watchOutgoingRequests() ?? Stream.value(const []);
});

final friendFeedProvider = FutureProvider.autoDispose<List<Activity>>((
  ref,
) async {
  final repository = ref.watch(socialRepositoryProvider);
  if (repository == null) return const [];
  final friends = await ref.watch(friendsProvider.future);
  return repository.feed(friends);
});

final friendActivityProvider = FutureProvider.autoDispose
    .family<List<Activity>, String>((ref, uid) async {
      final repository = ref.watch(socialRepositoryProvider);
      if (repository == null) return const [];
      return repository.activityOf(uid);
    });

final profileProvider = StreamProvider.autoDispose.family<Profile?, String>((
  ref,
  uid,
) {
  final repository = ref.watch(socialRepositoryProvider);
  return repository?.watchProfile(uid) ?? Stream.value(null);
});

final reviewsProvider = StreamProvider.autoDispose
    .family<List<Review>, String>((ref, bookKey) {
      final repository = ref.watch(socialRepositoryProvider);
      return repository?.watchReviews(bookKey) ?? Stream.value(const []);
    });

/// Whether reading activity is shared with friends (on by default).
final shareActivityProvider = StateNotifierProvider<ShareActivityNotifier, bool>(
  (ref) => ShareActivityNotifier()..load(),
);

class ShareActivityNotifier extends StateNotifier<bool> {
  ShareActivityNotifier() : super(true);

  static const _key = 'share_activity';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) state = preferences.getBool(_key) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_key, value);
  }
}

/// Human-readable message for Firestore failures shown in the UI.
String socialErrorMessage(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'You do not have access to this.',
      'unavailable' => 'You appear to be offline.',
      'not-found' || 'failed-precondition' =>
        'Social features are not set up for this app yet.',
      _ => error.message ?? 'Something went wrong (${error.code}).',
    };
  }
  if (error is UsernameTakenException) return error.toString();
  return 'Something went wrong: $error';
}

// ------------------------------------------------------------------ hooks
//
// Best-effort: social posting must never break reading, so failures are
// logged and swallowed.

Future<void> _post(
  Ref ref,
  Future<void> Function(SocialRepository repository) action,
) async {
  try {
    final repository = ref.read(socialRepositoryProvider);
    if (repository == null || !ref.read(shareActivityProvider)) return;
    final profile = await ref.read(myProfileProvider.future);
    if (profile == null) return;
    await action(repository);
  } catch (error) {
    debugPrint('Social activity not posted: $error');
  }
}

/// Activity helpers usable from widgets via `ref.read(socialActivityProvider)`.
final socialActivityProvider = Provider<SocialActivity>(SocialActivity.new);

class SocialActivity {
  SocialActivity(this._ref);

  final Ref _ref;

  Future<void> bookStarted(Book book) => _post(
    _ref,
    (repository) => repository.postActivity(
      type: ActivityType.started,
      title: book.title,
      author: book.author,
      bookKey: book.bookKey,
    ),
  );

  Future<void> bookFinished(Book book) => _post(_ref, (repository) async {
    await repository.postActivity(
      type: ActivityType.finished,
      title: book.title,
      author: book.author,
      bookKey: book.bookKey,
    );
    await syncProfileStats();
  });

  Future<void> badgesEarned(List<BadgeDefinition> badges) =>
      _post(_ref, (repository) async {
        // Avoid flooding friends when many badges unlock at once.
        for (final badge in badges.take(3)) {
          await repository.postActivity(
            type: ActivityType.badge,
            badgeId: badge.id,
            badgeTitle: badge.title,
          );
        }
        await syncProfileStats();
      });

  Future<void> reviewed(Book book, int rating) => _post(
    _ref,
    (repository) => repository.postActivity(
      type: ActivityType.review,
      title: book.title,
      author: book.author,
      bookKey: book.bookKey,
      rating: rating,
    ),
  );

  Future<ProfileStats> currentStats() async {
    final service = await _ref.read(achievementServiceProvider.future);
    final summary = await service.summary();
    final unlocks = await _ref.read(badgeUnlocksProvider.future);
    return ProfileStats(
      booksFinished: summary.finishedBooks,
      currentStreak: summary.currentStreak,
      longestStreak: summary.longestStreak,
      badgeCount: unlocks.length,
    );
  }

  /// Publishes current counts to the public profile when they changed.
  Future<void> syncProfileStats() async {
    try {
      final repository = _ref.read(socialRepositoryProvider);
      if (repository == null) return;
      final profile = await _ref.read(myProfileProvider.future);
      if (profile == null) return;
      final stats = await currentStats();
      if (stats.booksFinished == profile.booksFinished &&
          stats.currentStreak == profile.currentStreak &&
          stats.longestStreak == profile.longestStreak &&
          stats.badgeCount == profile.badgeCount) {
        return;
      }
      await repository.updateProfile(stats: stats);
    } catch (error) {
      debugPrint('Profile stats not synced: $error');
    }
  }
}


/// Installed in main.dart so badge unlocks reach friends.
List<BadgeUnlockListener> socialBadgeListeners(Ref ref) => [
  (badges) => ref.read(socialActivityProvider).badgesEarned(badges),
];
