import 'package:file_picker/file_picker.dart';

Future<List<int>> readPlatformFile(PlatformFile source) {
  final bytes = source.bytes;
  if (bytes == null) throw const FormatException('FILE DATA UNAVAILABLE.');
  return Future.value(bytes);
}

Future<String> writeBookFile(String hash, List<int> bytes) async {
  return 'web://books/$hash.epub';
}

Future<String> writeCoverFile(
  String hash,
  String extension,
  List<int> bytes,
) async {
  return 'web://covers/$hash.$extension';
}

Future<List<int>> readStoredBook(String path) {
  throw UnsupportedError('BOOK REFRESH IS NOT AVAILABLE ON WEB STORAGE.');
}
