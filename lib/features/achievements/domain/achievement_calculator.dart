import 'badges.dart';

/// Minimal book state the calculator needs (decoupled from Drift rows).
class BookProgress {
  const BookProgress({
    required this.id,
    required this.progressPercent,
    required this.isFinished,
    this.genre,
  });

  final int id;
  final double progressPercent;
  final bool isFinished;
  final String? genre;
}

class SessionRecord {
  const SessionRecord({
    required this.bookId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.startPercent,
    required this.endPercent,
  });

  final int bookId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSeconds;
  final double startPercent;
  final double endPercent;
}

class BadgeProgress {
  const BadgeProgress(this.current, this.target);

  final int current;
  final int target;

  double get fraction => target == 0 ? 1 : (current / target).clamp(0, 1);
}

class AchievementSummary {
  const AchievementSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.readingDays,
    required this.totalReadingTime,
    required this.finishedBooks,
    required this.finishedGenres,
    required this.genresKnown,
    required this.earned,
    required this.progress,
  });

  final int currentStreak;
  final int longestStreak;

  /// Distinct local calendar days that count as reading days.
  final Set<DateTime> readingDays;
  final Duration totalReadingTime;
  final int finishedBooks;
  final int finishedGenres;

  /// False until at least one book carries genre metadata.
  final bool genresKnown;
  final Set<String> earned;
  final Map<String, BadgeProgress> progress;
}

/// Pure badge and streak rules. Everything time-related uses the device's
/// local calendar day, because that is what "read every day" means to a
/// reader.
class AchievementCalculator {
  const AchievementCalculator({
    this.minimumDailySeconds = 60,
    this.abandonedAfter = const Duration(days: 14),
  });

  /// Reading time needed on a calendar day for it to count toward streaks.
  final int minimumDailySeconds;

  /// How long a book must be left untouched to count as abandoned.
  final Duration abandonedAfter;

  AchievementSummary calculate({
    required List<BookProgress> books,
    required List<SessionRecord> sessions,
    required int highlightCount,
    required DateTime now,
  }) {
    final days = readingDays(sessions);
    final current = currentStreak(days, now);
    final longest = longestStreak(days);
    final finished = books
        .where((book) => book.isFinished || book.progressPercent >= 100)
        .toList();
    final genres = finished
        .map((book) => book.genre?.trim().toLowerCase())
        .whereType<String>()
        .where((genre) => genre.isNotEmpty)
        .toSet();
    final genresKnown = books.any(
      (book) => book.genre?.trim().isNotEmpty == true,
    );
    final maxProgress = [
      ...books.map((book) => book.isFinished ? 100.0 : book.progressPercent),
      ...sessions.map((session) => session.endPercent),
    ].fold<double>(0, (max, value) => value > max ? value : max);
    final hadSession = sessions.any(
      (session) => session.durationSeconds >= minimumDailySeconds,
    );
    final comeback = hasComeback(sessions);
    final totalSeconds = sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationSeconds,
    );

    final progress = <String, BadgeProgress>{
      for (final badge in Badges.all)
        badge.id: switch (badge.category) {
          BadgeCategory.completion =>
            badge.id == Badges.genreExplorer.id
                ? BadgeProgress(genres.length, badge.target)
                : BadgeProgress(finished.length, badge.target),
          BadgeCategory.streak => BadgeProgress(longest, badge.target),
          BadgeCategory.progress => switch (badge.id) {
            'first_session' => BadgeProgress(hadSession ? 1 : 0, 1),
            'halfway_there' || 'finisher' => BadgeProgress(
              maxProgress.floor().clamp(0, 100),
              badge.target,
            ),
            'comeback_reader' => BadgeProgress(comeback ? 1 : 0, 1),
            'highlight_collector' => BadgeProgress(
              highlightCount,
              badge.target,
            ),
            _ => BadgeProgress(0, badge.target),
          },
        },
    };

    return AchievementSummary(
      currentStreak: current,
      longestStreak: longest,
      readingDays: days,
      totalReadingTime: Duration(seconds: totalSeconds),
      finishedBooks: finished.length,
      finishedGenres: genres.length,
      genresKnown: genresKnown,
      earned: {
        for (final entry in progress.entries)
          if (entry.value.current >= entry.value.target) entry.key,
      },
      progress: progress,
    );
  }

  /// Local calendar days with at least [minimumDailySeconds] of reading.
  /// Sessions are attributed to the day they started.
  Set<DateTime> readingDays(List<SessionRecord> sessions) {
    final totals = <DateTime, int>{};
    for (final session in sessions) {
      final local = session.startedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      totals[day] = (totals[day] ?? 0) + session.durationSeconds;
    }
    return {
      for (final entry in totals.entries)
        if (entry.value >= minimumDailySeconds) entry.key,
    };
  }

  /// Consecutive reading days ending today. A streak stays alive until the
  /// end of the day after the last reading day, so it does not reset at
  /// midnight before the reader has had a chance to read.
  int currentStreak(Set<DateTime> days, DateTime now) {
    final local = now.toLocal();
    final today = _ordinal(DateTime(local.year, local.month, local.day));
    final ordinals = days.map(_ordinal).toSet();
    var cursor = ordinals.contains(today)
        ? today
        : ordinals.contains(today - 1)
        ? today - 1
        : null;
    if (cursor == null) return 0;
    var streak = 0;
    while (ordinals.contains(cursor)) {
      streak++;
      cursor = cursor! - 1;
    }
    return streak;
  }

  int longestStreak(Set<DateTime> days) {
    final ordinals = days.map(_ordinal).toList()..sort();
    var longest = 0;
    var run = 0;
    int? previous;
    for (final day in ordinals) {
      run = previous != null && day == previous + 1 ? run + 1 : 1;
      if (run > longest) longest = run;
      previous = day;
    }
    return longest;
  }

  /// True when the reader returned to an unfinished book after leaving it for
  /// at least [abandonedAfter].
  bool hasComeback(List<SessionRecord> sessions) {
    final byBook = <int, List<SessionRecord>>{};
    for (final session in sessions) {
      byBook.putIfAbsent(session.bookId, () => []).add(session);
    }
    for (final list in byBook.values) {
      list.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      for (var i = 1; i < list.length; i++) {
        final before = list[i - 1];
        final after = list[i];
        final unfinished = before.endPercent < 99.5;
        final gap = after.startedAt.difference(before.endedAt);
        if (unfinished && gap >= abandonedAfter) return true;
      }
    }
    return false;
  }

  /// Day number independent of daylight-saving shifts.
  static int _ordinal(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
