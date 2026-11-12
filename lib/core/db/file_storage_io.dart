import 'dart:io';

Future<void> deleteStoredFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
