import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/db/app_database.dart';
import '../../../design/book_cover.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../../screens/settings_screen.dart';
import '../../achievements/data/achievement_service.dart';
import '../../book_detail/presentation/book_detail_screen.dart';
import '../../reader/presentation/reader_screen.dart';
import '../../social/presentation/friends_screen.dart';
import '../../stats/presentation/stats_screen.dart';

enum _Shelf { all, wantToRead, currentlyReading, finished }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const _gridKey = 'library_grid';

  _Shelf shelf = _Shelf.all;
  bool grid = true;
  bool importing = false;
  String query = '';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((preferences) {
      final saved = preferences.getBool(_gridKey);
      if (saved != null && mounted) setState(() => grid = saved);
    });
    // Award badges earned before this version tracked them (e.g. books that
    // were already finished), without a burst of notifications.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => checkAchievements(ref, announce: false),
    );
  }

  Future<void> _toggleLayout() async {
    setState(() => grid = !grid);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_gridKey, grid);
  }

  Future<void> _import() async {
    setState(() => importing = true);
    try {
      final service = await ref.read(importServiceProvider.future);
      final results = await service.pickAndImport();
      if (!mounted || results.isEmpty) return;
      final duplicates = results.where((result) => result.duplicate).length;
      final added = results.length - duplicates;
      _showMessage(switch ((added, duplicates)) {
        (_, 0) =>
          added == 1
              ? 'Added “${results.first.title}”.'
              : 'Added $added books.',
        (0, _) =>
          duplicates == 1
              ? '“${results.first.title}” is already in your library.'
              : 'Those books are already in your library.',
        _ => 'Added $added, skipped $duplicates already in your library.',
      });
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Import failed: $error');
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(message)),
    );
  }

  List<Book> _filtered(List<Book> books) {
    final value = switch (shelf) {
      _Shelf.wantToRead => 'wantToRead',
      _Shelf.currentlyReading => 'currentlyReading',
      _Shelf.finished => 'finished',
      _Shelf.all => null,
    };
    final normalizedQuery = query.trim().toLowerCase();
    return books.where((book) {
      final matchesShelf = value == null || book.shelf == value;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          book.title.toLowerCase().contains(normalizedQuery) ||
          book.author.toLowerCase().contains(normalizedQuery);
      return matchesShelf && matchesQuery;
    }).toList();
  }

  void _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);
    return Scaffold(
      appBar: BrutalAppBar(
        title: 'Bookmunity',
        actions: [
          IconButton(
            tooltip: grid ? 'List view' : 'Grid view',
            onPressed: _toggleLayout,
            icon: Icon(grid ? Icons.view_list_outlined : Icons.grid_view),
          ),
          IconButton(
            tooltip: 'Friends',
            onPressed: () => _push(const FriendsScreen()),
            icon: const Icon(Icons.people_outline),
          ),
          IconButton(
            tooltip: 'Reading stats and badges',
            onPressed: () => _push(const StatsScreen()),
            icon: const Icon(Icons.insights_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _push(const SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: importing ? null : _import,
        backgroundColor: BrutalColors.yellow,
        foregroundColor: BrutalColors.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BrutalTokens.borderRadius,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: BrutalTokens.borderWidth,
          ),
        ),
        icon: importing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add),
        label: Text(importing ? 'Importing…' : 'Add book'),
      ),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Your library could not be loaded',
          message: '$error',
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.local_library_outlined,
              title: 'Your library is empty',
              message: 'Add an EPUB from your device to start reading.',
              action: BrutalPressable(
                onPressed: importing ? null : _import,
                child: const Text('Add your first book'),
              ),
            );
          }
          final filtered = _filtered(items);
          final continueBook = items
              .where((book) => book.shelf == 'currentlyReading')
              .firstOrNull;
          final showContinue =
              continueBook != null &&
              shelf == _Shelf.all &&
              query.trim().isEmpty;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search by title or author',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _ShelfBar(
                  selected: shelf,
                  onSelected: (value) => setState(() => shelf = value),
                ),
              ),
              if (showContinue)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: _ContinueReading(
                      book: continueBook,
                      onOpen: () => _push(ReaderScreen(book: continueBook)),
                    ),
                  ),
                ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No matching books',
                    message: 'Try another shelf or search.',
                  ),
                )
              else if (grid)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.52,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (_, index) => _BookTile(
                      book: filtered[index],
                      onTap: () =>
                          _push(BookDetailScreen(book: filtered[index])),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, index) => _BookTile(
                      book: filtered[index],
                      compact: true,
                      onTap: () =>
                          _push(BookDetailScreen(book: filtered[index])),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ShelfBar extends StatelessWidget {
  const _ShelfBar({required this.selected, required this.onSelected});

  final _Shelf selected;
  final ValueChanged<_Shelf> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = {
      _Shelf.all: 'All',
      _Shelf.wantToRead: 'Want to read',
      _Shelf.currentlyReading: 'Reading',
      _Shelf.finished: 'Finished',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          for (final entry in labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BrutalChip(
                label: entry.value,
                selected: selected == entry.key,
                onPressed: () => onSelected(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading({required this.book, required this.onOpen});

  final Book book;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrutalCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          BookCover(
            title: book.title,
            coverPath: book.coverPath,
            width: 52,
            height: 76,
            shadow: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Continue reading', style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                BrutalProgressBar(value: book.progressPercent / 100, height: 6),
                const SizedBox(height: 4),
                Text(
                  '${book.progressPercent.floor()}% read',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.play_arrow_rounded, size: 30),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.onTap,
    this.compact = false,
  });

  final Book book;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          book.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          book.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (book.isFinished)
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                size: 14,
                color: BrutalColors.green,
              ),
              const SizedBox(width: 4),
              Text('Finished', style: theme.textTheme.bodySmall),
            ],
          )
        else if (book.progressPercent > 0) ...[
          BrutalProgressBar(value: book.progressPercent / 100, height: 6),
          const SizedBox(height: 3),
          Text(
            '${book.progressPercent.floor()}%',
            style: theme.textTheme.bodySmall,
          ),
        ] else
          Text('Not started', style: theme.textTheme.bodySmall),
      ],
    );
    return Semantics(
      button: true,
      label: '${book.title} by ${book.author}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BrutalTokens.smallBorderRadius,
        child: compact
            ? Row(
                children: [
                  BookCover(
                    title: book.title,
                    coverPath: book.coverPath,
                    width: 64,
                    height: 94,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: details),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BookCover(
                      title: book.title,
                      coverPath: book.coverPath,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 10),
                  details,
                ],
              ),
      ),
    );
  }
}
