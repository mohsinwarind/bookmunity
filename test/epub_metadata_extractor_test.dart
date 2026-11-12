import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:bookmunity/core/import/epub_metadata_extractor.dart';

void main() {
  const extractor = EpubMetadataExtractor();

  test('extracts EPUB2 namespaced metadata and meta cover', () {
    final archive = _epub(
      opfPath: 'OEBPS/content.opf',
      opf: '''
        <package xmlns="http://www.idpf.org/2007/opf">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>  The   Title  </dc:title>
            <dc:creator>Author One</dc:creator>
            <dc:creator>Author Two</dc:creator>
            <dc:identifier>urn:isbn:9781234567890</dc:identifier>
            <meta name="cover" content="cover-image"/>
          </metadata>
          <manifest>
            <item id="cover-image" href="images/cover.png" media-type="image/png"/>
            <item id="chapter" href="chapter.xhtml" media-type="application/xhtml+xml"/>
          </manifest>
          <spine><itemref idref="chapter"/></spine>
        </package>
      ''',
      files: {'OEBPS/images/cover.png': _imageBytes()},
    );

    final metadata = extractor.extract(archive, filename: 'wrong.epub');

    expect(metadata.title, 'The Title');
    expect(metadata.author, 'Author One, Author Two');
    expect(metadata.bookKey, '9781234567890');
    expect(metadata.coverBytes, isNotNull);
  });

  test('extracts EPUB3 title and properties cover with encoded paths', () {
    final archive = _epub(
      opfPath: 'book/package.opf',
      opf: '''
        <package xmlns="http://www.idpf.org/2007/opf">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>Modern Book</dc:title>
            <dc:creator opf:role="aut">Writer</dc:creator>
          </metadata>
          <manifest>
            <item id="cover" href="images/My%20Cover.png" media-type="image/png" properties="cover-image"/>
          </manifest>
          <spine/>
        </package>
      ''',
      files: {'book/images/My Cover.png': _imageBytes()},
    );

    final metadata = extractor.extract(archive);

    expect(metadata.title, 'Modern Book');
    expect(metadata.author, 'Writer');
    expect(metadata.coverBytes, isNotNull);
  });

  test('falls back to first spine heading and then filename', () {
    final archive = _epub(
      opfPath: 'content.opf',
      opf: '''
        <package xmlns="http://www.idpf.org/2007/opf">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"/>
          <manifest>
            <item id="chapter" href="chapter.xhtml" media-type="application/xhtml+xml"/>
          </manifest>
          <spine><itemref idref="chapter"/></spine>
        </package>
      ''',
      files: {
        'chapter.xhtml': utf8.encode(
          '<html><body><h1>  First Heading </h1></body></html>',
        ),
      },
    );

    final metadata = extractor.extract(archive, filename: 'fallback.epub');

    expect(metadata.title, 'First Heading');
    expect(metadata.author, 'UNKNOWN AUTHOR');
    expect(metadata.bookKey, 'first-heading|unknown-author');
  });
}

Archive _epub({
  required String opfPath,
  required String opf,
  Map<String, List<int>> files = const {},
}) {
  final archive = Archive()
    ..addFile(
      ArchiveFile(
        'META-INF/container.xml',
        utf8
            .encode(
              '<container><rootfiles><rootfile full-path="$opfPath"/></rootfiles></container>',
            )
            .length,
        utf8.encode(
          '<container><rootfiles><rootfile full-path="$opfPath"/></rootfiles></container>',
        ),
      ),
    )
    ..addFile(ArchiveFile(opfPath, utf8.encode(opf).length, utf8.encode(opf)));
  for (final entry in files.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  final encoded = ZipEncoder().encode(archive);
  return ZipDecoder().decodeBytes(encoded);
}

List<int> _imageBytes() {
  return image.encodePng(image.Image(width: 1, height: 1));
}
