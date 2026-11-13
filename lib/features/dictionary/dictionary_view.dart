import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import 'dictionary_service.dart';

final dictionaryServiceProvider = FutureProvider<DictionaryService>((
  ref,
) async {
  return DictionaryService(await ref.watch(databaseProvider.future));
});

/// Cached per word for the lifetime of the screen that asked.
final definitionProvider = FutureProvider.autoDispose
    .family<DictionaryResult, String>((ref, word) async {
      final service = await ref.watch(dictionaryServiceProvider.future);
      return service.lookup(word);
    });

/// Compact, Kindle-style definition preview shown with a word selection.
class DictionaryPreview extends ConsumerWidget {
  const DictionaryPreview({required this.word, this.onMore, super.key});

  final String word;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final result = ref.watch(definitionProvider(word));
    return InkWell(
      onTap: result.valueOrNull is DictionaryFound ? onMore : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: result.when(
          loading: () => Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text('Looking up “$word”…', style: theme.textTheme.bodySmall),
            ],
          ),
          error: (error, _) =>
              Text('Dictionary unavailable.', style: theme.textTheme.bodySmall),
          data: (value) => switch (value) {
            DictionaryFound(:final entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(entry.word, style: theme.textTheme.titleMedium),
                    if (entry.phonetic != null) ...[
                      const SizedBox(width: 8),
                      Text(entry.phonetic!, style: theme.textTheme.bodySmall),
                    ],
                    const Spacer(),
                    if (onMore != null)
                      Text(
                        'More',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.meanings.first.partOfSpeech.isEmpty ? '' : '${entry.meanings.first.partOfSpeech}. '}'
                  '${entry.shortDefinition ?? ''}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            DictionaryNotFound() => Text(
              'No dictionary entry for “$word”.',
              style: theme.textTheme.bodySmall,
            ),
            DictionaryOffline() => Text(
              'Connect to the internet to look up “$word”. Words you have looked up before work offline.',
              style: theme.textTheme.bodySmall,
            ),
          },
        ),
      ),
    );
  }
}

Future<void> showDictionarySheet(BuildContext context, String word) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, controller) =>
          _DictionaryDetail(word: word, controller: controller),
    ),
  );
}

class _DictionaryDetail extends ConsumerWidget {
  const _DictionaryDetail({required this.word, required this.controller});

  final String word;
  final ScrollController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final result = ref.watch(definitionProvider(word));
    return result.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Dictionary unavailable: $error')),
      data: (value) {
        if (value is! DictionaryFound) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Text(word, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(
                value is DictionaryOffline
                    ? 'You appear to be offline. Words you have looked up before are available without a connection.'
                    : 'No dictionary entry was found for this word.',
              ),
            ],
          );
        }
        final entry = value.entry;
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text(entry.word, style: theme.textTheme.headlineSmall),
            if (entry.phonetic != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(entry.phonetic!, style: theme.textTheme.bodySmall),
              ),
            for (final meaning in entry.meanings) ...[
              const SizedBox(height: 18),
              Text(
                meaning.partOfSpeech.isEmpty ? 'Meaning' : meaning.partOfSpeech,
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 6),
              for (final (index, sense) in meaning.senses.take(6).indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text(
                          '${index + 1}.',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sense.definition),
                            if (sense.example?.isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  '“${sense.example}”',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Text(
              'Definitions from dictionaryapi.dev (Wiktionary, CC BY-SA).',
              style: theme.textTheme.labelSmall,
            ),
          ],
        );
      },
    );
  }
}
