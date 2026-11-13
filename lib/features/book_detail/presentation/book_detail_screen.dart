import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../design/book_cover.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../achievements/data/achievement_service.dart';
import '../../highlights/presentation/highlights_screen.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../social/data/social_providers.dart';
import '../../social/presentation/reviews_section.dart';
import '../../../design/formatters.dart';

final _bookProvider = StreamProvider.autoDispose.family<Book?, int>((
  ref,
  id,
) async* {
  final database = await ref.watch(databaseProvider.future);
  yield* database.watchBook(id);
});

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.book, super.key});

  /// Initial snapshot; the screen follows live updates from the database.
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(_bookProvider(book.id));
    // Deleted while open: show the last snapshot until the route pops.
    final current = live.valueOrNull ?? book;
    return Scaffold(
      appBar: BrutalAppBar(
        title: current.title,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'More',
            onSelected: (value) => switch (value) {
              'refresh' => _refreshMetadata(context, ref, current),
              'delete' => _delete(context, ref, current),
              _ => null,
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'refresh', child: Text('Refresh metadata')),
              PopupMenuItem(value: 'delete', child: Text('Delete book')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Header(book: current),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: BrutalPressable(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReaderScreen(book: current)),
              ),
              backgroundColor: BrutalColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_outlined),
                  const SizedBox(width: 8),
                  Text(
                    current.progressPercent > 0 && !current.isFinished
                        ? 'Continue reading'
                        : current.isFinished
                        ? 'Read again'
                        : 'Start reading',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('Shelf'),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'wantToRead', label: Text('Want to read')),
              ButtonSegment(value: 'currentlyReading', label: Text('Reading')),
              ButtonSegment(value: 'finished', label: Text('Finished')),
            ],
            selected: {current.shelf},
            onSelectionChanged: (value) =>
                _changeShelf(context, ref, current, value.first),
          ),
          const SizedBox(height: 20),
          BrutalCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HighlightsScreen(book: current)),
            ),
            child: const Row(
              children: [
                Icon(Icons.format_quote_outlined),
                SizedBox(width: 12),
                Expanded(child: Text('Highlights and notes')),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('About this book'),
          _InfoRow(label: 'Author', value: current.author),
          if (current.genre != null)
            _InfoRow(label: 'Genre', value: current.genre!),
          _InfoRow(
            label: 'Progress',
            value: current.isFinished
                ? 'Finished${current.finishedAt == null ? '' : ' on ${formatDate(current.finishedAt!)}'}'
                : '${current.progressPercent.floor()}%',
          ),
          if (current.lastOpenedAt != null)
            _InfoRow(label: 'Last read', value: formatDate(current.lastOpenedAt!)),
          _InfoRow(label: 'Added', value: formatDate(current.addedAt)),
          const SizedBox(height: 24),
          ReviewsSection(book: current),
        ],
      ),
    );
  }

  Future<void> _changeShelf(
    BuildContext context,
    WidgetRef ref,
    Book current,
    String shelf,
  ) async {
    if (shelf == current.shelf) return;
    final database = await ref.read(databaseProvider.future);
    await database.updateShelf(current, shelf);
    final social = ref.read(socialActivityProvider);
    if (shelf == 'finished') {
      await checkAchievements(ref);
      await social.bookFinished(current);
    } else if (shelf == 'currentlyReading' && current.shelf == 'wantToRead') {
      await social.bookStarted(current);
    }
  }

  Future<void> _refreshMetadata(
    BuildContext context,
    WidgetRef ref,
    Book current,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = await ref.read(importServiceProvider.future);
      await service.refreshMetadata(current);
      messenger.showSnackBar(
        const SnackBar(content: Text('Metadata refreshed.')),
      );
    } on FormatException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Refresh failed: $error')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Book current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this book?'),
        content: Text(
          '“${current.title}” and its highlights, notes and bookmarks will be '
          'removed from this device. Your badges and reading history stay.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: BrutalColors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final database = await ref.read(databaseProvider.future);
    await database.deleteBook(current);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BookCover(
          title: book.title,
          coverPath: book.coverPath,
          width: 110,
          height: 160,
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(book.author, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              BrutalProgressBar(value: book.progressPercent / 100),
              const SizedBox(height: 6),
              Text(
                book.isFinished
                    ? 'Finished'
                    : '${book.progressPercent.floor()}% complete',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
