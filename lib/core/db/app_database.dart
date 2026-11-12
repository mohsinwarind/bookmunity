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

@DriftDatabase(tables: [Books, Highlights, DictionaryCaches])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        await m.addColumn(books, books.bookKey);
      }
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
  }) => (update(books)..where((item) => item.id.equals(book.id))).write(
    BooksCompanion(
      title: Value(title),
      author: Value(author),
      bookKey: Value(bookKey),
      coverPath: Value(coverPath),
    ),
  );

  Stream<List<Highlight>> watchHighlights(int bookId) =>
      (select(highlights)
            ..where((highlight) => highlight.bookId.equals(bookId))
            ..orderBy([(highlight) => OrderingTerm.desc(highlight.createdAt)]))
          .watch();

  Future<int> addHighlight(HighlightsCompanion highlight) =>
      into(highlights).insert(highlight);

  Future<void> deleteHighlight(int id) =>
      (delete(highlights)..where((highlight) => highlight.id.equals(id))).go();

  Future<void> updateHighlightNote(int id, String note) =>
      (update(highlights)..where((highlight) => highlight.id.equals(id))).write(
        HighlightsCompanion(
          note: Value(note.trim().isEmpty ? null : note.trim()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateReadingProgress(Book book, double progress) =>
      (update(books)..where((item) => item.id.equals(book.id))).write(
        BooksCompanion(
          progressPercent: Value(progress.clamp(0, 100)),
          lastOpenedAt: Value(DateTime.now()),
          shelf: Value(progress >= 100 ? 'finished' : 'currentlyReading'),
          isFinished: Value(progress >= 100),
          finishedAt: Value(progress >= 100 ? DateTime.now() : null),
        ),
      );

  Future<void> deleteBook(Book book) async {
    await transaction(() async {
      await (delete(
        highlights,
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
        ),
      );
}

Future<AppDatabase> openDatabase() async {
  return AppDatabase(await createDatabaseExecutor());
}
