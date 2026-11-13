import 'package:bookmunity/core/db/app_database.dart';
import 'package:bookmunity/features/achievements/data/achievement_service.dart';
import 'package:bookmunity/features/achievements/domain/badges.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late AchievementService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    service = AchievementService(database);
  });
  tearDown(() => database.close());

  test('newly earned badges are returned once and persisted', () async {
    final id = await database.addBook(
      BooksCompanion.insert(
        title: 'Book',
        filePath: '/x.epub',
        fileHash: 'h',
        addedAt: DateTime(2026),
      ),
    );
    await database.addReadingSession(
      ReadingSessionsCompanion.insert(
        bookId: id,
        startedAt: DateTime(2026, 11, 13, 9),
        endedAt: DateTime(2026, 11, 13, 9, 5),
        durationSeconds: 300,
      ),
    );
    final now = DateTime(2026, 11, 13, 10);
    final first = await service.evaluate(now: now);
    expect(first.map((badge) => badge.id), [Badges.firstSession.id]);
    expect(await service.evaluate(now: now), isEmpty);

    await database.saveReadingPosition(
      bookId: id,
      cfi: 'end',
      percent: 100,
      reachedEnd: true,
    );
    final second = await service.evaluate(now: now);
    expect(
      second.map((badge) => badge.id),
      containsAll([
        Badges.firstChapter.id,
        Badges.halfwayThere.id,
        Badges.finisher.id,
      ]),
    );
    final unlocked = await database.getBadgeUnlocks();
    expect(unlocked, hasLength(4));
  });

  test('badges are kept after the book is deleted', () async {
    final id = await database.addBook(
      BooksCompanion.insert(
        title: 'Gone',
        filePath: '/tmp/missing.epub',
        fileHash: 'g',
        addedAt: DateTime(2026),
      ),
    );
    await database.saveReadingPosition(
      bookId: id,
      cfi: 'end',
      percent: 100,
      reachedEnd: true,
    );
    await service.evaluate();
    await database.deleteBook((await database.getBooks()).single);
    expect(await service.evaluate(), isEmpty);
    expect(
      (await database.getBadgeUnlocks()).map((unlock) => unlock.badgeId),
      contains(Badges.firstChapter.id),
    );
  });
}
