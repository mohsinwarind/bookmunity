import 'package:bookmunity/core/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late int bookId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    bookId = await database.addBook(
      BooksCompanion.insert(
        title: 'Book',
        filePath: '/tmp/does-not-exist.epub',
        fileHash: 'hash',
        addedAt: DateTime(2026),
      ),
    );
  });
  tearDown(() => database.close());

  Future<Book> book() async => (await database.getBooks()).single;

  test('saving a position marks the book as currently reading', () async {
    await database.saveReadingPosition(
      bookId: bookId,
      cfi: 'c1',
      percent: 12.5,
      reachedEnd: false,
    );
    final saved = await book();
    expect(saved.lastCfi, 'c1');
    expect(saved.progressPercent, 12.5);
    expect(saved.shelf, 'currentlyReading');
    expect(saved.isFinished, isFalse);
    expect(saved.lastOpenedAt, isNotNull);
  });

  test('reaching the end finishes the book, and it stays finished', () async {
    await database.saveReadingPosition(
      bookId: bookId,
      cfi: 'end',
      percent: 99.8,
      reachedEnd: true,
    );
    var saved = await book();
    expect(saved.isFinished, isTrue);
    expect(saved.progressPercent, 100);
    expect(saved.shelf, 'finished');
    final finishedAt = saved.finishedAt;
    expect(finishedAt, isNotNull);

    // Paging back after finishing must not un-finish or move the date.
    await database.saveReadingPosition(
      bookId: bookId,
      cfi: 'earlier',
      percent: 80,
      reachedEnd: false,
    );
    saved = await book();
    expect(saved.isFinished, isTrue);
    expect(saved.shelf, 'finished');
    expect(saved.finishedAt, finishedAt);
    expect(saved.lastCfi, 'earlier');
  });

  test('marking finished from the shelf sets progress to 100%', () async {
    await database.updateShelf(await book(), 'finished');
    final saved = await book();
    expect(saved.isFinished, isTrue);
    expect(saved.progressPercent, 100);
    expect(saved.finishedAt, isNotNull);
  });

  test('locations cache round-trips', () async {
    await database.saveLocations(bookId, '["epubcfi(/6/2)"]');
    expect((await book()).locationsJson, '["epubcfi(/6/2)"]');
  });

  test('deleting a book removes highlights and bookmarks but keeps sessions', () async {
    await database.addHighlight(
      HighlightsCompanion.insert(
        bookId: bookId,
        cfiRange: 'r',
        selectedText: 't',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    await database.addBookmark(
      BookmarksCompanion.insert(bookId: bookId, cfi: 'b', createdAt: DateTime(2026)),
    );
    await database.addReadingSession(
      ReadingSessionsCompanion.insert(
        bookId: bookId,
        startedAt: DateTime(2026),
        endedAt: DateTime(2026),
        durationSeconds: 120,
      ),
    );
    await database.deleteBook(await book());
    expect(await database.getBooks(), isEmpty);
    expect(await database.countHighlights(), 0);
    expect(await database.watchBookmarks(bookId).first, isEmpty);
    expect(await database.getReadingSessions(), hasLength(1));
  });

  test('badge unlocks are idempotent and keep the first date', () async {
    await database.unlockBadges(['first_session'], DateTime(2026, 1, 1));
    await database.unlockBadges(['first_session', 'finisher'], DateTime(2026, 2, 1));
    final unlocks = {
      for (final unlock in await database.getBadgeUnlocks())
        unlock.badgeId: unlock.unlockedAt,
    };
    expect(unlocks.keys, unorderedEquals(['first_session', 'finisher']));
    expect(unlocks['first_session'], DateTime(2026, 1, 1));
  });

  test('dictionary cache upserts', () async {
    await database.cacheDefinition('word', 'a');
    await database.cacheDefinition('word', 'b');
    expect(await database.cachedDefinition('word'), 'b');
    expect(await database.cachedDefinition('other'), isNull);
  });

  test('highlight colour and note updates', () async {
    final id = await database.addHighlight(
      HighlightsCompanion.insert(
        bookId: bookId,
        cfiRange: 'r',
        selectedText: 't',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    await database.updateHighlightColor(id, 3);
    await database.updateHighlightNote(id, '  my note ');
    final saved = (await database.getHighlights(bookId)).single;
    expect(saved.color, 3);
    expect(saved.note, 'my note');
    await database.updateHighlightNote(id, '   ');
    expect((await database.getHighlights(bookId)).single.note, isNull);
  });

}
