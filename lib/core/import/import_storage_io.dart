import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<List<int>> readPlatformFile(PlatformFile source) async {
  final path = source.path;
  if (path == null) throw const FormatException('FILE PATH UNAVAILABLE.');
  return File(path).readAsBytes();
}

Future<String> writeBookFile(String hash, List<int> bytes) async {
  final directory = await getApplicationDocumentsDirectory();
  final books = Directory('${directory.path}/books');
  await books.create(recursive: true);
  final file = File('${books.path}/$hash.epub');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String> writeCoverFile(
  String hash,
  String extension,
  List<int> bytes,
) async {
  final directory = await getApplicationDocumentsDirectory();
  final covers = Directory('${directory.path}/covers');
  await covers.create(recursive: true);
  final file = File('${covers.path}/$hash.$extension');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<List<int>> readStoredBook(String path) => File(path).readAsBytes();
