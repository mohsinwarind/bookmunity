import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/db/app_database.dart';

class DictionarySense {
  const DictionarySense({required this.definition, this.example});

  final String definition;
  final String? example;
}

class DictionaryMeaning {
  const DictionaryMeaning({required this.partOfSpeech, required this.senses});

  final String partOfSpeech;
  final List<DictionarySense> senses;
}

class DictionaryEntry {
  const DictionaryEntry({
    required this.word,
    required this.meanings,
    this.phonetic,
  });

  final String word;
  final String? phonetic;
  final List<DictionaryMeaning> meanings;

  /// The first definition, for the compact Kindle-style preview.
  String? get shortDefinition =>
      meanings.isEmpty || meanings.first.senses.isEmpty
      ? null
      : meanings.first.senses.first.definition;

  /// Parses the dictionaryapi.dev response (a list of entries for one word).
  static DictionaryEntry? parse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! List || decoded.isEmpty) return null;
    final meanings = <DictionaryMeaning>[];
    String? word;
    String? phonetic;
    for (final rawEntry in decoded) {
      if (rawEntry is! Map) continue;
      word ??= rawEntry['word'] as String?;
      phonetic ??= _phonetic(rawEntry);
      for (final rawMeaning in rawEntry['meanings'] as List? ?? const []) {
        if (rawMeaning is! Map) continue;
        final senses = <DictionarySense>[
          for (final rawSense in rawMeaning['definitions'] as List? ?? const [])
            if (rawSense is Map &&
                (rawSense['definition'] as String?)?.trim().isNotEmpty == true)
              DictionarySense(
                definition: (rawSense['definition'] as String).trim(),
                example: (rawSense['example'] as String?)?.trim(),
              ),
        ];
        if (senses.isEmpty) continue;
        final partOfSpeech = (rawMeaning['partOfSpeech'] as String?) ?? '';
        final existing = meanings.indexWhere(
          (meaning) => meaning.partOfSpeech == partOfSpeech,
        );
        if (existing >= 0) {
          meanings[existing] = DictionaryMeaning(
            partOfSpeech: partOfSpeech,
            senses: [...meanings[existing].senses, ...senses],
          );
        } else {
          meanings.add(
            DictionaryMeaning(partOfSpeech: partOfSpeech, senses: senses),
          );
        }
      }
    }
    if (word == null || meanings.isEmpty) return null;
    return DictionaryEntry(word: word, phonetic: phonetic, meanings: meanings);
  }

  static String? _phonetic(Map<dynamic, dynamic> entry) {
    final direct = (entry['phonetic'] as String?)?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final item in entry['phonetics'] as List? ?? const []) {
      final text = item is Map ? (item['text'] as String?)?.trim() : null;
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}

sealed class DictionaryResult {
  const DictionaryResult();
}

class DictionaryFound extends DictionaryResult {
  const DictionaryFound(this.entry);
  final DictionaryEntry entry;
}

class DictionaryNotFound extends DictionaryResult {
  const DictionaryNotFound(this.word);
  final String word;
}

class DictionaryOffline extends DictionaryResult {
  const DictionaryOffline(this.word);
  final String word;
}

/// English definitions from the free dictionaryapi.dev service, cached in the
/// local database so a word looked up once works offline afterwards.
class DictionaryService {
  DictionaryService(this._database, {http.Client? client})
    : _client = client ?? http.Client();

  final AppDatabase _database;
  final http.Client _client;

  static Uri _uri(String word) => Uri.https(
    'api.dictionaryapi.dev',
    '/api/v2/entries/en/${Uri.encodeComponent(word)}',
  );

  /// Normalises a tapped word: lower case, curly apostrophes, possessives.
  static String normalize(String word) => word
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll(RegExp(r"'s$"), '')
      .replaceAll(RegExp(r"^[^a-z]+|[^a-z]+$"), '');

  /// Simple inflection fallbacks tried when the exact word has no entry.
  static List<String> candidates(String word) {
    final base = normalize(word);
    if (base.isEmpty) return const [];
    final options = <String>[base];
    void add(String value) {
      if (value.length >= 2 && !options.contains(value)) options.add(value);
    }

    if (base.endsWith('ies')) add('${base.substring(0, base.length - 3)}y');
    if (base.endsWith('ied')) add('${base.substring(0, base.length - 3)}y');
    if (base.endsWith('es')) add(base.substring(0, base.length - 2));
    if (base.endsWith('s') && !base.endsWith('ss')) {
      add(base.substring(0, base.length - 1));
    }
    if (base.endsWith('ed')) {
      add(base.substring(0, base.length - 2));
      add(base.substring(0, base.length - 1));
    }
    if (base.endsWith('ing')) {
      final stem = base.substring(0, base.length - 3);
      add(stem);
      add('${stem}e');
      if (stem.length > 2 && stem[stem.length - 1] == stem[stem.length - 2]) {
        add(stem.substring(0, stem.length - 1));
      }
    }
    if (base.endsWith('ly')) add(base.substring(0, base.length - 2));
    if (base.endsWith('er')) add(base.substring(0, base.length - 2));
    if (base.endsWith('est')) add(base.substring(0, base.length - 3));
    return options;
  }

  Future<DictionaryResult> lookup(String word) async {
    final options = candidates(word);
    if (options.isEmpty) return DictionaryNotFound(word);
    var offline = false;
    for (final candidate in options) {
      final cached = await _database.cachedDefinition(candidate);
      if (cached != null) {
        final entry = DictionaryEntry.parse(cached);
        if (entry != null) return DictionaryFound(entry);
      }
      try {
        final response = await _client
            .get(_uri(candidate))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final body = utf8.decode(response.bodyBytes);
          final entry = DictionaryEntry.parse(body);
          if (entry != null) {
            await _database.cacheDefinition(candidate, body);
            return DictionaryFound(entry);
          }
        } else if (response.statusCode != 404) {
          offline = true;
        }
      } on TimeoutException {
        offline = true;
        break;
      } catch (_) {
        offline = true;
        break;
      }
    }
    return offline ? DictionaryOffline(word) : DictionaryNotFound(word);
  }
}
