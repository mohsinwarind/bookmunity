import 'package:drift/drift.dart';

import 'database_connection.dart';
import 'file_storage.dart';

part 'app_database.g.dart';

class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get author => text().withDefault(const Constant('UNKNOWN'))();
  TextColumn get coverPath => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get fileHash => text().unique()();
  TextColumn get bookKey => text().withDefault(const Constant(''))();
  TextColumn get shelf => text().withDefault(const Constant('wantToRead'))();
  DateTimeColumn get addedAt => dateTime()();
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();
  TextColumn get lastCfi => text().nullable()();
  RealColumn get progressPercent => real().withDefault(const Constant(0))();
  IntColumn get totalLocations => integer().nullable()();
  BoolColumn get isFinished => boolean().withDefault(const Constant(false))();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get genre => text().nullable()();
  TextColumn get locationsJson => text().nullable()();
}

class Highlights extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get cfiRange => text()();
  TextColumn get selectedText => text()();
  IntColumn get color => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  TextColumn get chapterTitle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class DictionaryCaches extends Table {
  TextColumn get word => text()();
  TextColumn get responseJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {word};
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId =>
      integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get cfi => text()();
  TextColumn get label => text().nullable()();
  RealColumn get percent => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// One stretch of active reading. Sessions survive book deletion on purpose:
/// streaks and badges describe the reader, not the current library.
class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  RealColumn get startPercent => real().withDefault(const Constant(0))();
  RealColumn get endPercent => real().withDefault(const Constant(0))();
}

class BadgeUnlocks extends Table {
  TextColumn get badgeId => text()();
  DateTimeColumn get unlockedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {badgeId};
}

@DriftDatabase(
  tables: [
    Books,
    Highlights,
    DictionaryCaches,
    Bookmarks,
    ReadingSessions,
    BadgeUnlocks,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        await m.addColumn(books, books.bookKey);
      }
      if (from < 4) {
        await m.addColumn(books, books.genre);
        await m.addColumn(books, books.locationsJson);
        await m.createTable(bookmarks);
        await m.createTable(readingSessions);
        await m.createTable(badgeUnlocks);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Stream<List<Book>> watchBooks() => (select(
    books,
  )..orderBy([(book) => OrderingTerm.desc(book.lastOpenedAt)])).watch();

  Future<List<Book>> getBooks() => select(books).get();

  Future<Book?> findBookByHash(String hash) => (select(
    books,
  )..where((book) => book.fileHash.equals(hash))).getSingleOrNull();

  Future<int> addBook(BooksCompanion book) => into(books).insert(book);

  Future<void> updateMetadata({
    required Book book,
    required String title,
    required String author,
    required String bookKey,
    required String? coverPath,
    String? genre,
  }) => (update(books)..where((item) => item.id.equals(book.id))).write(
    BooksCompanion(
      title: Value(title),
      author: Value(author),
      bookKey: Value(bookKey),
      coverPath: Value(coverPath),
      genre: Value(genre),
    ),
  );

  Stream<Book?> watchBook(int id) =>
      (select(books)..where((book) => book.id.equals(id))).watchSingleOrNull();

  Stream<List<Highlight>> watchHighlights(int bookId) =>
      (select(highlights)
            ..where((highlight) => highlight.bookId.equals(bookId))
            ..orderBy([(highlight) => OrderingTerm.desc(highlight.createdAt)]))
          .watch();

  Future<List<Highlight>> getHighlights(int bookId) => (select(
    highlights,
  )..where((highlight) => highlight.bookId.equals(bookId))).get();

  Future<int> countHighlights() => _highlightCount().getSingle();

  Stream<int> watchHighlightCount() => _highlightCount().watchSingle();

  Selectable<int> _highlightCount() {
    final count = highlights.id.count();
    return (selectOnly(
      highlights,
    )..addColumns([count])).map((row) => row.read(count) ?? 0);
  }

  Future<int> addHighlight(HighlightsCompanion highlight) =>
      into(highlights).insert(highlight);

  Future<void> updateHighlightColor(int id, int color) =>
      (update(highlights)..where((highlight) => highlight.id.equals(id))).write(
        HighlightsCompanion(
          color: Value(color),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteHighlight(int id) =>
      (delete(highlights)..where((highlight) => highlight.id.equals(id))).go();

  Future<void> updateHighlightNote(int id, String note) =>
      (update(highlights)..where((highlight) => highlight.id.equals(id))).write(
        HighlightsCompanion(
          note: Value(note.trim().isEmpty ? null : note.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Saves the reader position. Finishing is sticky: once a book reaches the
  /// end it stays finished even if the reader pages back afterwards.
  Future<void> saveReadingPosition({
    required int bookId,
    required String? cfi,
    required double percent,
    required bool reachedEnd,
  }) async {
    await transaction(() async {
      final current = await (select(
        books,
      )..where((book) => book.id.equals(bookId))).getSingleOrNull();
      if (current == null) return;
      final finishedNow = reachedEnd && !current.isFinished;
      await (update(books)..where((book) => book.id.equals(bookId))).write(
        BooksCompanion(
          lastCfi: Value(cfi),
          progressPercent: Value(reachedEnd ? 100 : percent.clamp(0, 100)),
          lastOpenedAt: Value(DateTime.now()),
          shelf: Value(
            current.isFinished || reachedEnd ? 'finished' : 'currentlyReading',
          ),
          isFinished: Value(current.isFinished || reachedEnd),
          finishedAt: finishedNow
              ? Value(DateTime.now())
              : const Value.absent(),
        ),
      );
    });
  }

  Future<void> saveLocations(int bookId, String json) =>
      (update(books)..where((book) => book.id.equals(bookId))).write(
        BooksCompanion(locationsJson: Value(json)),
      );

  Stream<List<Bookmark>> watchBookmarks(int bookId) =>
      (select(bookmarks)
            ..where((bookmark) => bookmark.bookId.equals(bookId))
            ..orderBy([(bookmark) => OrderingTerm.asc(bookmark.percent)]))
          .watch();

  Future<int> addBookmark(BookmarksCompanion bookmark) =>
      into(bookmarks).insert(bookmark);

  Future<void> deleteBookmark(int id) =>
      (delete(bookmarks)..where((bookmark) => bookmark.id.equals(id))).go();

  Future<void> addReadingSession(ReadingSessionsCompanion session) =>
      into(readingSessions).insert(session);

  Future<List<ReadingSession>> getReadingSessions() => (select(
    readingSessions,
  )..orderBy([(session) => OrderingTerm.asc(session.startedAt)])).get();

  Stream<List<ReadingSession>> watchReadingSessions() =>
      select(readingSessions).watch();

  Future<List<BadgeUnlock>> getBadgeUnlocks() => select(badgeUnlocks).get();

  Stream<List<BadgeUnlock>> watchBadgeUnlocks() => select(badgeUnlocks).watch();

  Future<void> unlockBadges(Iterable<String> badgeIds, DateTime at) async {
    await batch((batch) {
      batch.insertAll(
        badgeUnlocks,
        badgeIds.map(
          (id) => BadgeUnlocksCompanion.insert(badgeId: id, unlockedAt: at),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<String?> cachedDefinition(String word) async {
    final row = await (select(
      dictionaryCaches,
    )..where((entry) => entry.word.equals(word))).getSingleOrNull();
    return row?.responseJson;
  }

  Future<void> cacheDefinition(String word, String json) =>
      into(dictionaryCaches).insertOnConflictUpdate(
        DictionaryCachesCompanion.insert(
          word: word,
          responseJson: json,
          cachedAt: DateTime.now(),
        ),
      );

  Future<void> deleteBook(Book book) async {
    await transaction(() async {
      await (delete(
        highlights,
      )..where((item) => item.bookId.equals(book.id))).go();
      await (delete(
        bookmarks,
      )..where((item) => item.bookId.equals(book.id))).go();
      await (delete(books)..where((item) => item.id.equals(book.id))).go();
      await deleteStoredFile(book.filePath);
      if (book.coverPath != null) {
        await deleteStoredFile(book.coverPath!);
      }
    });
  }

  Future<void> updateShelf(Book book, String shelf) =>
      (update(books)..where((item) => item.id.equals(book.id))).write(
        BooksCompanion(
          shelf: Value(shelf),
          isFinished: Value(shelf == 'finished'),
          finishedAt: Value(shelf == 'finished' ? DateTime.now() : null),
          progressPercent: shelf == 'finished'
              ? const Value(100)
              : const Value.absent(),
        ),
      );
}

Future<AppDatabase> openDatabase() async {
  return AppDatabase(await createDatabaseExecutor());
}
