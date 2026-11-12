import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';

import '../db/app_database.dart';
import 'epub_metadata_extractor.dart';
import 'import_storage.dart';

class ImportResult {
  const ImportResult({required this.title, required this.duplicate});

  final String title;
  final bool duplicate;
}

class EpubImportService {
  EpubImportService(this.database);

  final AppDatabase database;

  Future<List<ImportResult>> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['epub'],
      withData: true,
    );
    if (result == null) return const [];

    final imported = <ImportResult>[];
    for (final selected in result.files) {
      imported.add(await importFile(selected));
    }
    return imported;
  }

  Future<ImportResult> importFile(PlatformFile source) async {
    final bytes = await readPlatformFile(source);
    final hash = sha256.convert(bytes).toString();
    final existing = await database.findBookByHash(hash);
    if (existing != null) {
      return ImportResult(title: existing.title, duplicate: true);
    }

    final archive = ZipDecoder().decodeBytes(bytes);
    final names = archive.files.map((file) => file.name).toSet();
    if (!names.contains('META-INF/container.xml')) {
      throw const FormatException('NOT A VALID EPUB.');
    }
    if (names.contains('META-INF/rights.xml') ||
        names.contains('META-INF/encryption.xml')) {
      throw const FormatException('DRM PROTECTED. CANNOT OPEN.');
    }

    final metadata = await _extractMetadata(archive, source.name);
    final destination = await writeBookFile(hash, bytes);
    String? coverPath;
    if (metadata.coverBytes != null) {
      coverPath = await writeCoverFile(hash, 'jpg', metadata.coverBytes!);
    }

    final now = DateTime.now();
    await database.addBook(
      BooksCompanion.insert(
        title: metadata.title,
        author: Value(metadata.author),
        filePath: destination,
        fileHash: hash,
        bookKey: Value(metadata.bookKey),
        addedAt: now,
        coverPath: Value(coverPath),
      ),
    );
    return ImportResult(title: metadata.title, duplicate: false);
  }

  Future<EpubMetadata> _extractMetadata(Archive archive, String? filename) {
    return Isolate.run(
      () => const EpubMetadataExtractor().extract(archive, filename: filename),
    );
  }

  Future<void> refreshMetadata(Book book) async {
    final bytes = await readStoredBook(book.filePath);
    final archive = ZipDecoder().decodeBytes(bytes);
    final metadata = await _extractMetadata(archive, book.filePath);
    String? coverPath;
    if (metadata.coverBytes != null) {
      coverPath = await writeCoverFile(
        book.fileHash,
        'jpg',
        metadata.coverBytes!,
      );
    }
    await database.updateMetadata(
      book: book,
      title: metadata.title,
      author: metadata.author,
      bookKey: metadata.bookKey,
      coverPath: coverPath,
    );
  }

  Future<int> refreshAllMetadata() async {
    final books = await database.getBooks();
    var refreshed = 0;
    for (final book in books) {
      try {
        await refreshMetadata(book);
        refreshed++;
      } on FormatException {
        // Keep a malformed book available; its reading state is not changed.
      }
    }
    return refreshed;
  }
}
