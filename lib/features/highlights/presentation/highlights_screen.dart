import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';

class HighlightsScreen extends ConsumerWidget {
  const HighlightsScreen({required this.book, super.key});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider).valueOrNull;
    if (database == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: BrutalAppBar(title: 'Highlights'),
      body: StreamBuilder<List<Highlight>>(
        stream: database.watchHighlights(book.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('HIGHLIGHTS ERROR: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final highlights = snapshot.data!;
          if (highlights.isEmpty) {
            return const Center(
              child: BrutalCard(
                backgroundColor: BrutalColors.yellow,
                child: Text('NO HIGHLIGHTS YET.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: highlights.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final highlight = highlights[index];
              return BrutalCard(
                backgroundColor: BrutalColors.yellow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“${highlight.selectedText}”',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(height: 1.5, fontStyle: FontStyle.italic),
                    ),
                    if (highlight.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text('NOTE: ${highlight.note}'),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      highlight.createdAt.toLocal().toString().split('.').first,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        children: [
                          TextButton(
                            onPressed: () =>
                                _editNote(context, database, highlight),
                            child: const Text('NOTE'),
                          ),
                          TextButton(
                            onPressed: () =>
                                database.deleteHighlight(highlight.id),
                            child: const Text('DELETE'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editNote(
    BuildContext context,
    AppDatabase database,
    Highlight highlight,
  ) async {
    final controller = TextEditingController(text: highlight.note ?? '');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NOTE'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'ADD A NOTE'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              await database.updateHighlightNote(highlight.id, controller.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}
