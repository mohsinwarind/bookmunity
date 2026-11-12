import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class EpubBookReader {
  const EpubBookReader();

  static Future<String> readBook(String filePath) async {
    if (filePath.startsWith('web://')) {
      return 'This book was imported in a web-safe format and cannot be read in a native desktop preview.';
    }

    final bytes = await File(filePath).readAsBytes();
    return extractText(bytes);
  }

  static String extractText(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final containerXml = _readFileText(archive, 'META-INF/container.xml');
    final rootFilePath = XmlDocument.parse(containerXml)
        .findAllElements('rootfile')
        .firstOrNull
        ?.getAttribute('full-path');

    if (rootFilePath == null || rootFilePath.isEmpty) {
      return 'This EPUB does not include a readable book manifest.';
    }

    final opfXml = _readFileText(archive, rootFilePath);
    final opf = XmlDocument.parse(opfXml);
    final items = opf.findAllElements('item').where((element) {
      final href = element.getAttribute('href') ?? '';
      final mediaType = element.getAttribute('media-type') ?? '';
      return mediaType.contains('xhtml') ||
          href.toLowerCase().endsWith('.xhtml') ||
          href.toLowerCase().endsWith('.html');
    }).toList();

    if (items.isEmpty) {
      return 'This EPUB does not contain any readable chapter content.';
    }

    final segments = <String>[];
    for (final item in items) {
      final href = item.getAttribute('href');
      if (href == null || href.isEmpty) continue;
      final path = _resolvePath(rootFilePath, href);
      if (!archive.files.any((file) => file.name == path)) continue;

      final chapterXml = _readFileText(archive, path);
      final chapterDocument = XmlDocument.parse(chapterXml);
      final text = chapterDocument.descendants
          .whereType<XmlText>()
          .map((node) => node.toString().trim())
          .where((value) => value.isNotEmpty)
          .join(' ');

      if (text.isNotEmpty) {
        segments.add(text);
      }
    }

    return segments.isEmpty
        ? 'This EPUB is imported, but it does not provide readable text content.'
        : segments.join('\n\n');
  }

  static String _resolvePath(String rootFilePath, String href) {
    final lastSlash = rootFilePath.lastIndexOf('/');
    if (lastSlash < 0) return href;
    return '${rootFilePath.substring(0, lastSlash + 1)}$href';
  }

  static String _readFileText(Archive archive, String name) {
    final file = archive.files.firstWhere(
      (entry) => entry.name == name,
      orElse: () => ArchiveFile(name, 0, <int>[]),
    );
    if (file.content.isEmpty) {
      return '';
    }
    return String.fromCharCodes(file.content);
  }
}
