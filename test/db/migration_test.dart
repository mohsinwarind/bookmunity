import 'package:bookmunity/core/db/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';
import '../generated_migrations/schema_v3.dart' as v3;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('upgrading v3 -> v4 produces the expected schema', () async {
    final connection = await verifier.startAt(3);
    final database = AppDatabase(connection);
    await verifier.migrateAndValidate(database, 4);
    await database.close();
  });

  test('upgrading v3 -> v4 keeps books and highlights', () async {
    final schema = await verifier.schemaAt(3);
    final old = v3.DatabaseAtV3(schema.newConnection());
    await old.into(old.books).insert(
      v3.BooksCompanion.insert(
        title: 'Alice',
        filePath: '/books/a.epub',
        fileHash: 'hash-a',
        addedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
        progressPercent: const Value(42),
        lastCfi: const Value('epubcfi(/6/4!/4/2/1:0)'),
      ),
    );
    await old.into(old.highlights).insert(
      v3.HighlightsCompanion.insert(
        bookId: 1,
        cfiRange: 'epubcfi(/6/4!/4/2,/1:0,/1:5)',
        selectedText: 'Alice',
        createdAt: 0,
        updatedAt: 0,
      ),
    );
    await old.close();

    final database = AppDatabase(schema.newConnection());
    final books = await database.getBooks();
    expect(books.single.title, 'Alice');
    expect(books.single.progressPercent, 42);
    expect(books.single.lastCfi, 'epubcfi(/6/4!/4/2/1:0)');
    expect(books.single.genre, isNull);
    expect(await database.countHighlights(), 1);
    expect(await database.getReadingSessions(), isEmpty);
    await database.close();
  });
}
