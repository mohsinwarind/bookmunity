import 'dart:convert';

import 'package:bookmunity/core/db/app_database.dart';
import 'package:bookmunity/features/dictionary/dictionary_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _body = '''
[{"word":"rabbit","phonetic":"/ˈɹæbɪt/","meanings":[
  {"partOfSpeech":"noun","definitions":[{"definition":"A mammal of the family Leporidae.","example":"The rabbit hopped."}]},
  {"partOfSpeech":"verb","definitions":[{"definition":"To hunt rabbits."}]}]},
 {"word":"rabbit","meanings":[{"partOfSpeech":"noun","definitions":[{"definition":"A runner who sets the pace."}]}]}]
''';

void main() {
  test('parses and merges meanings by part of speech', () {
    final entry = DictionaryEntry.parse(_body)!;
    expect(entry.word, 'rabbit');
    expect(entry.phonetic, '/ˈɹæbɪt/');
    expect(entry.meanings.map((m) => m.partOfSpeech), ['noun', 'verb']);
    expect(entry.meanings.first.senses, hasLength(2));
    expect(entry.shortDefinition, 'A mammal of the family Leporidae.');
  });

  test('rejects empty responses', () {
    expect(DictionaryEntry.parse('[]'), isNull);
    expect(DictionaryEntry.parse('{"title":"No Definitions Found"}'), isNull);
  });

  test('candidate forms for inflected words', () {
    expect(DictionaryService.candidates('Rabbits'), ['rabbits', 'rabbit']);
    expect(DictionaryService.candidates('hurried'), contains('hurry'));
    expect(DictionaryService.candidates('running'), contains('run'));
    expect(DictionaryService.candidates('making'), contains('make'));
    expect(DictionaryService.candidates("Alice’s"), ['alice']);
  });

  group('lookup', () {
    late AppDatabase database;
    setUp(() => database = AppDatabase(NativeDatabase.memory()));
    tearDown(() => database.close());

    test('falls back to the stem and caches the hit', () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        final word = request.url.pathSegments.last;
        requested.add(word);
        return word == 'rabbit'
            ? http.Response.bytes(_utf8(_body), 200)
            : http.Response('{}', 404);
      });
      final service = DictionaryService(database, client: client);
      final result = await service.lookup('Rabbits');
      expect(result, isA<DictionaryFound>());
      expect(requested, ['rabbits', 'rabbit']);

      // Second lookup is served from the cache without the network.
      final offline = DictionaryService(
        database,
        client: MockClient((_) async => throw Exception('offline')),
      );
      expect(await offline.lookup('rabbit'), isA<DictionaryFound>());
    });

    test('reports offline instead of not-found when the network fails', () async {
      final service = DictionaryService(
        database,
        client: MockClient((_) async => throw Exception('no network')),
      );
      expect(await service.lookup('gryphon'), isA<DictionaryOffline>());
    });

    test('reports not found on 404', () async {
      final service = DictionaryService(
        database,
        client: MockClient((_) async => http.Response('{}', 404)),
      );
      expect(await service.lookup('zzzq'), isA<DictionaryNotFound>());
    });
  });
}

List<int> _utf8(String value) => const Utf8Codec().encode(value);
