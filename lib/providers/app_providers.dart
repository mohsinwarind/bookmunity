import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import '../core/import/epub_import_service.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await openDatabase();
  ref.onDispose(database.close);
  return database;
});

final importServiceProvider = FutureProvider<EpubImportService>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return EpubImportService(database);
});

final booksProvider = StreamProvider<List<Book>>((ref) async* {
  final database = await ref.watch(databaseProvider.future);
  yield* database.watchBooks();
});
