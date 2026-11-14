import 'dart:convert';

import 'package:bookmunity/features/reader/data/reader_bridge.dart';
import 'package:bookmunity/providers/settings_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderEvent', () {
    test('parses event name and payload from the JS bridge', () {
      final event = ReaderEvent.fromRaw({
        'event': 'relocated',
        'payload': {'cfi': 'epubcfi(/6/4!/4/2/1:0)'},
      });
      expect(event.name, 'relocated');
      expect(event.payload['cfi'], 'epubcfi(/6/4!/4/2/1:0)');
    });

    test('tolerates malformed input', () {
      final event = ReaderEvent.fromRaw('nonsense');
      expect(event.name, '');
      expect(event.payload, isEmpty);
    });
  });

  group('ReaderLocation', () {
    ReaderLocation location(Map<String, Object?> overrides) =>
        ReaderLocation.fromJson({
          'cfi': 'a',
          'endCfi': 'b',
          'href': 'ch1.xhtml',
          'index': 2,
          'chapterTitle': 'Chapter 1',
          'percentage': null,
          'page': 3,
          'totalPages': 10,
          'atStart': false,
          'atEnd': false,
          'bookmarkCfis': <String>[],
          ...overrides,
        });

    test('percentage is null until locations are ready', () {
      expect(location({}).percentage, isNull);
      expect(location({'percentage': 0.42}).percentage, 0.42);
    });

    test('pages left in chapter', () {
      expect(location({}).pagesLeftInChapter, 7);
      expect(location({'page': 10}).pagesLeftInChapter, 0);
      expect(location({'page': 0, 'totalPages': 0}).pagesLeftInChapter, isNull);
    });

    test('reachedEnd from atEnd or ~100%', () {
      expect(location({}).reachedEnd, isFalse);
      expect(location({'atEnd': true}).reachedEnd, isTrue);
      expect(location({'percentage': 0.996}).reachedEnd, isTrue);
      expect(location({'percentage': 0.98}).reachedEnd, isFalse);
    });

    test('bookmarked when a bookmark is on the page', () {
      expect(location({}).bookmarked, isFalse);
      expect(
        location({
          'bookmarkCfis': ['x'],
        }).bookmarked,
        isTrue,
      );
    });
  });

  group('ReaderSelection.singleWord', () {
    ReaderSelection selection(String text) =>
        ReaderSelection(cfiRange: 'c', text: text, chapterTitle: '');

    test('accepts a single word and strips punctuation', () {
      expect(selection('serendipity').singleWord, 'serendipity');
      expect(selection('“Curiouser,”').singleWord, 'Curiouser');
      expect(selection("rabbit's").singleWord, "rabbit's");
      expect(selection('well-known').singleWord, 'well-known');
    });

    test('rejects phrases and non-words', () {
      expect(selection('two words').singleWord, isNull);
      expect(selection('1865').singleWord, isNull);
      expect(selection('').singleWord, isNull);
    });
  });

  test('TocItem list skips entries without href and labels blanks', () {
    final items = TocItem.listFrom({
      'items': [
        {'label': 'One', 'href': 'a.xhtml', 'depth': 0},
        {'label': '  ', 'href': 'b.xhtml#x', 'depth': 1},
        {'label': 'Broken', 'href': '', 'depth': 0},
      ],
    });
    expect(items.map((item) => item.label), ['One', 'Untitled section']);
    expect(items[1].depth, 1);
  });

  test('start command encodes settings, highlights and empty cfi as null', () {
    final script = ReaderCommands.start(
      url: 'http://127.0.0.1:1/book.epub',
      cfi: '',
      settings: const ReaderSettings().toReaderJson(),
      highlights: [
        {'id': 1, 'cfiRange': 'r', 'color': 2},
      ],
      bookmarks: const ['b'],
      locations: null,
    );
    expect(script, startsWith('window.startReader('));
    final json =
        jsonDecode(script.substring(19, script.length - 2))
            as Map<String, dynamic>;
    expect(json['cfi'], isNull);
    expect(json['settings']['flow'], 'paginated');
    expect(json['highlights'][0]['color'], 2);
    expect(json['bookmarks'], ['b']);
  });

  test('commands are valid JSON calls', () {
    final script = ReaderCommands.command('search', {'query': 'a "quoted" word'});
    final json =
        jsonDecode(script.substring(21, script.length - 2))
            as Map<String, dynamic>;
    expect(json['name'], 'search');
    expect(json['args']['query'], 'a "quoted" word');
  });
}
