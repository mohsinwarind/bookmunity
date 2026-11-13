import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_messenger.dart';
import '../../../core/db/app_database.dart';
import '../../../providers/app_providers.dart';
import '../domain/achievement_calculator.dart';
import '../domain/badges.dart';

List<BookProgress> _bookProgress(List<Book> books) => [
  for (final book in books)
    BookProgress(
      id: book.id,
      progressPercent: book.progressPercent,
      isFinished: book.isFinished,
      genre: book.genre,
    ),
];

List<SessionRecord> _sessionRecords(List<ReadingSession> sessions) => [
  for (final session in sessions)
    SessionRecord(
      bookId: session.bookId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      durationSeconds: session.durationSeconds,
      startPercent: session.startPercent,
      endPercent: session.endPercent,
    ),
];

class AchievementService {
  AchievementService(
    this._database, {
    this.calculator = const AchievementCalculator(),
  });

  final AppDatabase _database;
  final AchievementCalculator calculator;

  Future<AchievementSummary> summary({DateTime? now}) async {
    final books = await _database.getBooks();
    final sessions = await _database.getReadingSessions();
    final highlightCount = await _database.countHighlights();
    return calculator.calculate(
      books: _bookProgress(books),
      sessions: _sessionRecords(sessions),
      highlightCount: highlightCount,
      now: now ?? DateTime.now(),
    );
  }

  /// Persists newly earned badges and returns them. Unlocks are permanent:
  /// deleting a book or highlight later never takes a badge away.
  Future<List<BadgeDefinition>> evaluate({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final result = await summary(now: at);
    final unlocked = (await _database.getBadgeUnlocks())
        .map((unlock) => unlock.badgeId)
        .toSet();
    final fresh = result.earned.difference(unlocked);
    if (fresh.isEmpty) return const [];
    await _database.unlockBadges(fresh, at);
    return [
      for (final badge in Badges.all)
        if (fresh.contains(badge.id)) badge,
    ];
  }
}

final achievementServiceProvider = FutureProvider<AchievementService>((
  ref,
) async {
  return AchievementService(await ref.watch(databaseProvider.future));
});

final readingSessionsProvider = StreamProvider<List<ReadingSession>>((
  ref,
) async* {
  final database = await ref.watch(databaseProvider.future);
  yield* database.watchReadingSessions();
});

final badgeUnlocksProvider = StreamProvider<List<BadgeUnlock>>((ref) async* {
  final database = await ref.watch(databaseProvider.future);
  yield* database.watchBadgeUnlocks();
});

final highlightCountProvider = StreamProvider<int>((ref) async* {
  final database = await ref.watch(databaseProvider.future);
  yield* database.watchHighlightCount();
});

/// Live summary for the stats screen, recomputed when books, sessions or
/// highlights change.
final achievementSummaryProvider = Provider<AsyncValue<AchievementSummary>>((
  ref,
) {
  final books = ref.watch(booksProvider);
  final sessions = ref.watch(readingSessionsProvider);
  final highlights = ref.watch(highlightCountProvider);
  for (final value in [books, sessions, highlights]) {
    if (value.hasError) return AsyncValue.error(value.error!, value.stackTrace!);
  }
  if (!books.hasValue || !sessions.hasValue || !highlights.hasValue) {
    return const AsyncValue.loading();
  }
  return AsyncValue.data(
    const AchievementCalculator().calculate(
      books: _bookProgress(books.requireValue),
      sessions: _sessionRecords(sessions.requireValue),
      highlightCount: highlights.requireValue,
      now: DateTime.now(),
    ),
  );
});

/// Listeners notified about newly unlocked badges (e.g. social activity).
typedef BadgeUnlockListener =
    Future<void> Function(List<BadgeDefinition> badges);

final badgeUnlockListenersProvider = Provider<List<BadgeUnlockListener>>(
  (ref) => [],
);

/// Checks for new badges and announces them. Safe to call often.
Future<void> checkAchievements(WidgetRef ref, {bool announce = true}) async {
  try {
    final service = await ref.read(achievementServiceProvider.future);
    await checkAchievementsWith(
      service,
      ref.read(badgeUnlockListenersProvider),
      announce: announce,
    );
  } catch (error, stack) {
    debugPrint('Achievement check failed: $error\n$stack');
  }
}

/// Variant for callers that can no longer use a `ref` (e.g. `dispose`).
Future<void> checkAchievementsWith(
  AchievementService service,
  List<BadgeUnlockListener> listeners, {
  bool announce = true,
}) async {
  try {
    final unlocked = await service.evaluate();
    if (unlocked.isEmpty) return;
    if (announce) _announce(unlocked);
    for (final listener in listeners) {
      await listener(unlocked);
    }
  } catch (error, stack) {
    debugPrint('Achievement check failed: $error\n$stack');
  }
}

void _announce(List<BadgeDefinition> badges) {
  final messenger = appMessengerKey.currentState;
  if (messenger == null) return;
  final first = badges.first;
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Icon(first.icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              badges.length == 1
                  ? 'Badge unlocked: ${first.title}'
                  : '${badges.length} badges unlocked, including ${first.title}',
            ),
          ),
        ],
      ),
    ),
  );
}
