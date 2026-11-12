import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as image;
import 'package:xml/xml.dart';

class EpubMetadata {
  const EpubMetadata({
    required this.title,
    required this.author,
    required this.bookKey,
    required this.coverBytes,
  });

  final String title;
  final String author;
  final String bookKey;
  final List<int>? coverBytes;
}

class EpubMetadataExtractor {
  const EpubMetadataExtractor();

  EpubMetadata extract(Archive archive, {String? filename}) {
    final container = _document(archive, 'META-INF/container.xml');
    final rootfile = _elements(container, 'rootfile')
        .map((element) => _attribute(element, 'full-path'))
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (rootfile.isEmpty) {
      throw const FormatException('EPUB CONTENT MISSING.');
    }

    final opf = _document(archive, rootfile);
    final metadata = _elements(opf, 'metadata').firstOrNull;
    final manifest = _elements(opf, 'manifest').firstOrNull;
    final spine = _elements(opf, 'spine').firstOrNull;
    final items = manifest == null
        ? const <XmlElement>[]
        : _elements(manifest, 'item');

    final title =
        _firstMetadata(metadata, 'title') ??
        _firstSpineHeading(archive, rootfile, spine, items) ??
        _filenameFallback(filename);
    final author = _metadataValues(metadata, 'creator').join(', ');
    final identifier = _metadataValues(metadata, 'identifier').firstOrNull;
    final cover = _findCover(archive, rootfile, opf, items, spine);

    return EpubMetadata(
      title: _clean(title),
      author: author.isEmpty ? 'UNKNOWN AUTHOR' : _clean(author),
      bookKey: _bookKey(
        identifier,
        title,
        author.isEmpty ? 'UNKNOWN AUTHOR' : author,
      ),
      coverBytes: cover == null ? null : _resizeCover(cover),
    );
  }

  XmlDocument _document(Archive archive, String path) {
    final file = archive.files.firstWhere(
      (entry) => _normalizePath(entry.name) == _normalizePath(path),
      orElse: () => ArchiveFile(path, 0, <int>[]),
    );
    if (file.content.isEmpty) {
      throw const FormatException('EPUB CONTENT MISSING.');
    }
    return XmlDocument.parse(utf8.decode(file.content));
  }

  List<XmlElement> _elements(XmlNode node, String localName) => node.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == localName)
      .toList();

  String _attribute(XmlElement element, String name) {
    return element.attributes
            .where((attribute) => attribute.name.local == name)
            .map((attribute) => attribute.value)
            .firstOrNull ??
        '';
  }

  String? _firstMetadata(XmlElement? metadata, String localName) {
    if (metadata == null) return null;
    return _metadataValues(metadata, localName).firstOrNull;
  }

  List<String> _metadataValues(XmlElement? metadata, String localName) {
    if (metadata == null) return const [];
    return _elements(metadata, localName)
        .map((element) => _clean(element.innerText))
        .where((value) => value.isNotEmpty)
        .toList();
  }

  String? _firstSpineHeading(
    Archive archive,
    String rootfile,
    XmlElement? spine,
    List<XmlElement> items,
  ) {
    if (spine == null) return null;
    final firstIdref = _elements(spine, 'itemref')
        .map((element) => _attribute(element, 'idref'))
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (firstIdref.isEmpty) return null;
    final item = items
        .where((entry) => _attribute(entry, 'id') == firstIdref)
        .firstOrNull;
    final href = item == null ? '' : _attribute(item, 'href');
    if (href.isEmpty) return null;
    final document = _document(archive, _resolvePath(rootfile, href));
    final heading = document.descendants
        .whereType<XmlElement>()
        .where((element) => RegExp(r'^h[1-6]$').hasMatch(element.name.local))
        .map((element) => _clean(element.innerText))
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    return heading.isEmpty ? null : heading;
  }

  List<int>? _findCover(
    Archive archive,
    String rootfile,
    XmlDocument opf,
    List<XmlElement> items,
    XmlElement? spine,
  ) {
    XmlElement? coverItem;
    coverItem = items.where((item) {
      return _attribute(
        item,
        'properties',
      ).split(RegExp(r'\s+')).contains('cover-image');
    }).firstOrNull;

    coverItem ??= () {
      final coverId = _elements(opf, 'meta')
          .where((meta) => _attribute(meta, 'name') == 'cover')
          .map((meta) => _attribute(meta, 'content'))
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      return items
          .where((item) => _attribute(item, 'id') == coverId)
          .firstOrNull;
    }();

    coverItem ??= items.where((item) {
      final mediaType = _attribute(item, 'media-type');
      final marker = '${_attribute(item, 'id')} ${_attribute(item, 'href')}'
          .toLowerCase();
      return mediaType.startsWith('image/') && marker.contains('cover');
    }).firstOrNull;

    if (coverItem == null) {
      final guideCover = _elements(opf, 'reference').where((reference) {
        return _attribute(reference, 'type').toLowerCase() == 'cover';
      }).firstOrNull;
      if (guideCover != null) {
        return _fileBytes(
          archive,
          _resolvePath(rootfile, _attribute(guideCover, 'href')),
        );
      }
    }

    if (coverItem != null) {
      return _fileBytes(
        archive,
        _resolvePath(rootfile, _attribute(coverItem, 'href')),
      );
    }

    return _firstSpineImage(archive, rootfile, spine, items);
  }

  List<int>? _firstSpineImage(
    Archive archive,
    String rootfile,
    XmlElement? spine,
    List<XmlElement> items,
  ) {
    if (spine == null) return null;
    final idref = _elements(spine, 'itemref')
        .map((element) => _attribute(element, 'idref'))
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final item = items
        .where((entry) => _attribute(entry, 'id') == idref)
        .firstOrNull;
    if (item == null) return null;
    final document = _document(
      archive,
      _resolvePath(rootfile, _attribute(item, 'href')),
    );
    final imageSource = _elements(document, 'img')
        .map((element) => _attribute(element, 'src'))
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    return imageSource.isEmpty
        ? null
        : _fileBytes(
            archive,
            _resolvePath(
              _resolvePath(rootfile, _attribute(item, 'href')),
              imageSource,
            ),
          );
  }

  List<int>? _fileBytes(Archive archive, String path) {
    final normalized = _normalizePath(path);
    return archive.files
        .where((file) => _normalizePath(file.name) == normalized)
        .map((file) => file.content)
        .firstOrNull;
  }

  List<int>? _resizeCover(List<int> bytes) {
    final decoded = image.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) return null;
    final resized = decoded.width > 600
        ? image.copyResize(decoded, width: 600)
        : decoded;
    return image.encodeJpg(resized, quality: 88);
  }

  String _resolvePath(String baseFile, String href) {
    final decoded = Uri.decodeFull(href.split('#').first);
    final base = baseFile.substring(0, baseFile.lastIndexOf('/') + 1);
    return _normalizePath('$base$decoded');
  }

  String _normalizePath(String path) {
    final segments = path.replaceAll('\\', '/').split('/');
    final normalized = <String>[];
    for (final segment in segments) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..' && normalized.isNotEmpty) {
        normalized.removeLast();
      } else if (segment != '..') {
        normalized.add(segment);
      }
    }
    return normalized.join('/');
  }

  String _filenameFallback(String? filename) {
    final value = filename?.split(RegExp(r'[/\\]')).last ?? 'UNTITLED BOOK';
    return value.replaceFirst(RegExp(r'\.[^.]+$'), '');
  }

  String _bookKey(String? identifier, String title, String author) {
    final isbn = identifier?.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (isbn != null && (isbn.length == 10 || isbn.length == 13)) {
      return isbn.toUpperCase();
    }
    return '${_slug(title)}|${_slug(author)}';
  }

  String _slug(String value) =>
      _clean(value)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');

  String _clean(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
}
