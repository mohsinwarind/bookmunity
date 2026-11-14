import 'dart:convert';

/// Typed view of the messages exchanged with `assets/reader/reader.js`.
/// See docs/reader_bridge.md.

double? _double(Object? value) => value is num ? value.toDouble() : null;

int _int(Object? value) => value is num ? value.toInt() : 0;

String _string(Object? value) => value is String ? value : '';

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

class ReaderEvent {
  const ReaderEvent(this.name, this.payload);

  factory ReaderEvent.fromRaw(Object? raw) {
    final map = _map(raw);
    return ReaderEvent(_string(map['event']), _map(map['payload']));
  }

  final String name;
  final Map<String, dynamic> payload;
}

class ReaderLocation {
  const ReaderLocation({
    required this.cfi,
    required this.endCfi,
    required this.href,
    required this.index,
    required this.chapterTitle,
    required this.percentage,
    required this.location,
    required this.totalLocations,
    required this.page,
    required this.totalPages,
    required this.atStart,
    required this.atEnd,
    required this.bookmarkCfis,
  });

  factory ReaderLocation.fromJson(Map<String, dynamic> json) => ReaderLocation(
    cfi: _string(json['cfi']),
    endCfi: _string(json['endCfi']),
    href: _string(json['href']),
    index: _int(json['index']),
    chapterTitle: _string(json['chapterTitle']),
    percentage: _double(json['percentage']),
    location: json['location'] is num ? _int(json['location']) : null,
    totalLocations: json['totalLocations'] is num
        ? _int(json['totalLocations'])
        : null,
    page: _int(json['page']),
    totalPages: _int(json['totalPages']),
    atStart: json['atStart'] == true,
    atEnd: json['atEnd'] == true,
    bookmarkCfis: (json['bookmarkCfis'] as List? ?? const [])
        .whereType<String>()
        .toList(),
  );

  final String cfi;
  final String endCfi;
  final String href;
  final int index;
  final String chapterTitle;

  /// 0..1 across the whole book; null until locations are generated.
  final double? percentage;
  final int? location;
  final int? totalLocations;

  /// Page within the current chapter (paginated mode only).
  final int page;
  final int totalPages;
  final bool atStart;
  final bool atEnd;

  /// Bookmarks that fall on the visible page.
  final List<String> bookmarkCfis;

  bool get bookmarked => bookmarkCfis.isNotEmpty;

  /// Pages left in the chapter, when the reader knows them.
  int? get pagesLeftInChapter => totalPages > 0 && page > 0
      ? (totalPages - page).clamp(0, totalPages)
      : null;

  /// True when the reader is on the last page, or effectively at 100%.
  bool get reachedEnd => atEnd || (percentage != null && percentage! >= 0.995);
}

class TocItem {
  const TocItem({required this.label, required this.href, required this.depth});

  factory TocItem.fromJson(Map<String, dynamic> json) => TocItem(
    label: _string(json['label']).trim().isEmpty
        ? 'Untitled section'
        : _string(json['label']).trim(),
    href: _string(json['href']),
    depth: _int(json['depth']),
  );

  final String label;
  final String href;
  final int depth;

  static List<TocItem> listFrom(Map<String, dynamic> payload) =>
      (payload['items'] as List? ?? const [])
          .map((item) => TocItem.fromJson(_map(item)))
          .where((item) => item.href.isNotEmpty)
          .toList();
}

class ReaderSelection {
  const ReaderSelection({
    required this.cfiRange,
    required this.text,
    required this.chapterTitle,
  });

  factory ReaderSelection.fromJson(Map<String, dynamic> json) =>
      ReaderSelection(
        cfiRange: _string(json['cfiRange']),
        text: _string(json['text']).trim(),
        chapterTitle: _string(json['chapterTitle']),
      );

  final String cfiRange;
  final String text;
  final String chapterTitle;

  static final _wordPattern = RegExp(r"^[\p{L}][\p{L}'’\-]*$", unicode: true);

  /// A single word, stripped of surrounding punctuation, or null.
  String? get singleWord {
    final stripped = text.replaceAll(
      RegExp(r"^[^\p{L}]+|[^\p{L}]+$", unicode: true),
      '',
    );
    if (stripped.isEmpty || stripped.length > 40) return null;
    return _wordPattern.hasMatch(stripped) ? stripped : null;
  }
}

class SearchResult {
  const SearchResult({
    required this.cfi,
    required this.excerpt,
    required this.chapterTitle,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    cfi: _string(json['cfi']),
    excerpt: _string(json['excerpt']),
    chapterTitle: _string(json['chapterTitle']),
  );

  final String cfi;
  final String excerpt;
  final String chapterTitle;

  static List<SearchResult> listFrom(Map<String, dynamic> payload) =>
      (payload['results'] as List? ?? const [])
          .map((item) => SearchResult.fromJson(_map(item)))
          .where((item) => item.cfi.isNotEmpty)
          .toList();
}

/// Builds the JavaScript snippets Flutter evaluates in the WebView.
abstract final class ReaderCommands {
  static String command(String name, [Map<String, Object?> args = const {}]) =>
      'window.readerCommand(${jsonEncode({'name': name, 'args': args})});';

  static String start({
    required String url,
    required String? cfi,
    required Map<String, Object> settings,
    required List<Map<String, Object?>> highlights,
    required List<String> bookmarks,
    required String? locations,
  }) =>
      'window.startReader(${jsonEncode({'url': url, 'cfi': (cfi?.isEmpty ?? true) ? null : cfi, 'settings': settings, 'highlights': highlights, 'bookmarks': bookmarks, 'locations': locations})});';
}
