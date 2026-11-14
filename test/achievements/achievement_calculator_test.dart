import 'package:bookmunity/features/achievements/domain/achievement_calculator.dart';
import 'package:bookmunity/features/achievements/domain/badges.dart';
import 'package:flutter_test/flutter_test.dart';

const calculator = AchievementCalculator();

SessionRecord session(
  DateTime start, {
  int seconds = 600,
  int bookId = 1,
  double startPercent = 0,
  double endPercent = 10,
}) => SessionRecord(
  bookId: bookId,
  startedAt: start,
  endedAt: start.add(Duration(seconds: seconds)),
  durationSeconds: seconds,
  startPercent: startPercent,
  endPercent: endPercent,
);

List<SessionRecord> daily(DateTime first, int days, {int seconds = 600}) => [
  for (var i = 0; i < days; i++)
    session(DateTime(first.year, first.month, first.day + i, 21), seconds: seconds),
];

BookProgress finishedBook(int id, {String? genre}) =>
    BookProgress(id: id, progressPercent: 100, isFinished: true, genre: genre);

AchievementSummary calc({
  List<BookProgress> books = const [],
  List<SessionRecord> sessions = const [],
  int highlights = 0,
  DateTime? now,
}) => calculator.calculate(
  books: books,
  sessions: sessions,
  highlightCount: highlights,
  now: now ?? DateTime(2026, 11, 13, 12),
);

void main() {
  group('reading days', () {
    test('a day needs at least a minute of reading in total', () {
      final day = DateTime(2026, 11, 10, 9);
      expect(calculator.readingDays([session(day, seconds: 59)]), isEmpty);
      expect(
        calculator.readingDays([
          session(day, seconds: 30),
          session(day.add(const Duration(hours: 5)), seconds: 30),
        ]),
        {DateTime(2026, 11, 10)},
      );
    });

    test('sessions are attributed to the local day they started', () {
      final lateNight = DateTime(2026, 11, 10, 23, 55);
      expect(calculator.readingDays([session(lateNight, seconds: 900)]), {
        DateTime(2026, 11, 10),
      });
    });
  });

  group('streaks', () {
    final now = DateTime(2026, 11, 13, 12);

    test('no sessions means no streak', () {
      final summary = calc(now: now);
      expect(summary.currentStreak, 0);
      expect(summary.longestStreak, 0);
    });

    test('consecutive days ending today', () {
      final summary = calc(sessions: daily(DateTime(2026, 11, 9), 5), now: now);
      expect(summary.currentStreak, 5);
      expect(summary.longestStreak, 5);
    });

    test('streak survives until the end of the next day', () {
      // Read 9th-12th, nothing yet on the 13th: streak is still alive.
      final summary = calc(sessions: daily(DateTime(2026, 11, 9), 4), now: now);
      expect(summary.currentStreak, 4);
    });

    test('a missed day resets the current streak but not the longest', () {
      final sessions = [
        ...daily(DateTime(2026, 11, 1), 6), // 1st-6th
        ...daily(DateTime(2026, 11, 12), 2), // 12th-13th
      ];
      final summary = calc(sessions: sessions, now: now);
      expect(summary.currentStreak, 2);
      expect(summary.longestStreak, 6);
    });

    test('streak is broken after a full missed day', () {
      final summary = calc(sessions: daily(DateTime(2026, 11, 5), 7), now: now);
      expect(summary.currentStreak, 0); // last read on the 11th
      expect(summary.longestStreak, 7);
    });

    test('several sessions on one day count once', () {
      final day = DateTime(2026, 11, 13, 8);
      final summary = calc(
        sessions: [session(day), session(day.add(const Duration(hours: 3)))],
        now: now,
      );
      expect(summary.currentStreak, 1);
    });

    test('streaks span month boundaries and DST changes', () {
      // 25 Oct - 3 Nov crosses the end of October and the EU/US DST switch.
      final summary = calc(
        sessions: daily(DateTime(2026, 10, 25), 10),
        now: DateTime(2026, 11, 3, 22),
      );
      expect(summary.currentStreak, 10);
      expect(summary.longestStreak, 10);
    });
  });

  group('streak badges', () {
    test('unlock at 2, 3, 7, 14, 30 and 100 days', () {
      Set<String> earnedAfter(int days) => calc(
        sessions: daily(DateTime(2026, 1, 1), days),
        now: DateTime(2026, 1, 1).add(Duration(days: days - 1)),
      ).earned;

      expect(earnedAfter(1), isNot(contains(Badges.readingSpark.id)));
      expect(earnedAfter(2), contains(Badges.readingSpark.id));
      expect(earnedAfter(3), contains(Badges.steadyReader.id));
      expect(earnedAfter(6), isNot(contains(Badges.weeklyReader.id)));
      expect(earnedAfter(7), contains(Badges.weeklyReader.id));
      expect(earnedAfter(14), contains(Badges.dedicatedReader.id));
      expect(earnedAfter(30), contains(Badges.readingHabit.id));
      expect(earnedAfter(99), isNot(contains(Badges.readingChampion.id)));
      expect(earnedAfter(100), contains(Badges.readingChampion.id));
    });

    test('streak badges use the longest streak, so a lapse keeps them', () {
      final summary = calc(
        sessions: daily(DateTime(2026, 10, 1), 7),
        now: DateTime(2026, 11, 13),
      );
      expect(summary.currentStreak, 0);
      expect(summary.earned, contains(Badges.weeklyReader.id));
    });
  });

  group('completion badges', () {
    test('count finished books', () {
      Set<String> earned(int count) =>
          calc(books: [for (var i = 0; i < count; i++) finishedBook(i)]).earned;
      expect(earned(0), isNot(contains(Badges.firstChapter.id)));
      expect(earned(1), containsAll([Badges.firstChapter.id, Badges.finisher.id]));
      expect(earned(3), contains(Badges.bookStarter.id));
      expect(earned(5), contains(Badges.bookworm.id));
      expect(earned(10), contains(Badges.avidReader.id));
      expect(earned(24), isNot(contains(Badges.libraryLegend.id)));
      expect(earned(25), contains(Badges.libraryLegend.id));
    });

    test('a 100% book counts even if the flag was not set', () {
      final summary = calc(
        books: const [BookProgress(id: 1, progressPercent: 100, isFinished: false)],
      );
      expect(summary.finishedBooks, 1);
    });

    test('genre explorer needs 5 distinct genres among finished books', () {
      final books = [
        finishedBook(1, genre: 'Fantasy'),
        finishedBook(2, genre: 'fantasy'), // same genre, different case
        finishedBook(3, genre: 'Mystery'),
        finishedBook(4, genre: 'Romance'),
        finishedBook(5, genre: 'History'),
        const BookProgress(id: 6, progressPercent: 30, isFinished: false, genre: 'Poetry'),
      ];
      var summary = calc(books: books);
      expect(summary.genresKnown, isTrue);
      expect(summary.finishedGenres, 4);
      expect(summary.earned, isNot(contains(Badges.genreExplorer.id)));

      summary = calc(books: [...books, finishedBook(7, genre: 'Poetry')]);
      expect(summary.earned, contains(Badges.genreExplorer.id));
    });

    test('genres are unknown until any book has one', () {
      expect(calc(books: [finishedBook(1)]).genresKnown, isFalse);
    });
  });

  group('progress badges', () {
    test('first session needs a minute of reading', () {
      final day = DateTime(2026, 11, 13, 9);
      expect(
        calc(sessions: [session(day, seconds: 30)]).earned,
        isNot(contains(Badges.firstSession.id)),
      );
      expect(
        calc(sessions: [session(day, seconds: 60)]).earned,
        contains(Badges.firstSession.id),
      );
    });

    test('halfway there from book progress', () {
      expect(
        calc(books: const [BookProgress(id: 1, progressPercent: 49.9, isFinished: false)]).earned,
        isNot(contains(Badges.halfwayThere.id)),
      );
      expect(
        calc(books: const [BookProgress(id: 1, progressPercent: 50, isFinished: false)]).earned,
        contains(Badges.halfwayThere.id),
      );
    });

    test('highlight collector at 10 highlights', () {
      expect(calc(highlights: 9).earned, isNot(contains(Badges.highlightCollector.id)));
      expect(calc(highlights: 10).earned, contains(Badges.highlightCollector.id));
      expect(calc(highlights: 4).progress[Badges.highlightCollector.id]!.fraction, 0.4);
    });

    test('comeback reader: returning to an unfinished book after 14 days', () {
      final first = session(DateTime(2026, 10, 1, 20), endPercent: 30);
      final back13 = session(DateTime(2026, 10, 14, 19), startPercent: 30);
      final back15 = session(DateTime(2026, 10, 16, 21), startPercent: 30);
      expect(calc(sessions: [first, back13]).earned, isNot(contains(Badges.comebackReader.id)));
      expect(calc(sessions: [first, back15]).earned, contains(Badges.comebackReader.id));
    });

    test('comeback ignores finished books and different books', () {
      final finished = session(DateTime(2026, 10, 1, 20), endPercent: 100);
      final reread = session(DateTime(2026, 11, 1, 20));
      expect(calc(sessions: [finished, reread]).earned, isNot(contains(Badges.comebackReader.id)));

      final bookA = session(DateTime(2026, 10, 1, 20), bookId: 1, endPercent: 20);
      final bookB = session(DateTime(2026, 11, 1, 20), bookId: 2);
      expect(calc(sessions: [bookA, bookB]).earned, isNot(contains(Badges.comebackReader.id)));
    });
  });

  test('total reading time sums sessions', () {
    final summary = calc(
      sessions: [
        session(DateTime(2026, 11, 1), seconds: 90),
        session(DateTime(2026, 11, 2), seconds: 30),
      ],
    );
    expect(summary.totalReadingTime, const Duration(minutes: 2));
  });

  test('every badge has a unique id and a progress entry', () {
    final ids = Badges.all.map((badge) => badge.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(calc().progress.keys, containsAll(ids));
    expect(Badges.all, hasLength(17));
  });
}
