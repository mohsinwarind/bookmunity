class EpubBookReader {
  const EpubBookReader();

  static Future<String> readBook(String filePath) async {
    return 'EPUB reading is available on native builds. This project imported this book in a browser-safe placeholder format.';
  }

  static String extractText(List<int> bytes) {
    return 'EPUB reading is available on native builds. This project does not read browser-stored files directly.';
  }
}
