import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../reader/domain/reader_palette.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../reader/presentation/widgets/selection_panels.dart';
import '../../../design/formatters.dart';

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
      appBar: const BrutalAppBar(title: 'Highlights and notes'),
      body: StreamBuilder<List<Highlight>>(
        stream: database.watchHighlights(book.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Highlights could not be loaded',
              message: '${snapshot.error}',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final highlights = snapshot.data!;
          if (highlights.isEmpty) {
            return const EmptyState(
              icon: Icons.format_quote_outlined,
              title: 'No highlights yet',
              message:
                  'While reading, press and hold on a passage to highlight it or add a note.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: highlights.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) => _HighlightCard(
              book: book,
              highlight: highlights[index],
              database: database,
            ),
          );
        },
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.book,
    required this.highlight,
    required this.database,
  });

  final Book book;
  final Highlight highlight;
  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrutalCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              ReaderScreen(book: book, initialCfi: highlight.cfiRange),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: highlightSwatch(highlight.color),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    highlight.selectedText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                if (highlight.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    highlight.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [
                          if (highlight.chapterTitle?.isNotEmpty == true)
                            highlight.chapterTitle!,
                          formatDate(highlight.createdAt),
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    PopupMenuButton<int>(
                      tooltip: 'Colour',
                      icon: const Icon(Icons.palette_outlined, size: 20),
                      onSelected: (color) =>
                          database.updateHighlightColor(highlight.id, color),
                      itemBuilder: (_) => [
                        for (var i = 0; i < highlightSwatches.length; i++)
                          PopupMenuItem(
                            value: i,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 9,
                                  backgroundColor: highlightSwatches[i],
                                ),
                                const SizedBox(width: 10),
                                Text(highlightSwatchNames[i]),
                              ],
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      tooltip: highlight.note?.isNotEmpty == true
                          ? 'Edit note'
                          : 'Add note',
                      icon: const Icon(Icons.edit_note, size: 22),
                      onPressed: () async {
                        final note = await showNoteDialog(
                          context,
                          initial: highlight.note ?? '',
                          quote: highlight.selectedText,
                        );
                        if (note != null) {
                          await database.updateHighlightNote(
                            highlight.id,
                            note,
                          );
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete highlight',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await database.deleteHighlight(highlight.id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Highlight deleted.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => database.addHighlight(highlight.toCompanion(true)),
        ),
      ),
    );
  }
}
