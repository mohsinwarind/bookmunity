import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../book_detail/presentation/book_detail_screen.dart';
import '../../../features/stats/presentation/stats_screen.dart';
import '../../../screens/settings_screen.dart';

enum _Shelf { all, wantToRead, currentlyReading, finished }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _Shelf shelf = _Shelf.all;
  bool grid = true;
  bool importing = false;
  String query = '';

  Future<void> _import() async {
    setState(() => importing = true);
    try {
      final service = await ref.read(importServiceProvider.future);
      final results = await service.pickAndImport();
      if (!mounted || results.isEmpty) return;
      final duplicates = results.where((result) => result.duplicate).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicates == 0
                ? 'IMPORTED ${results.length} BOOK(S).'
                : '$duplicates BOOK(S) ALREADY IN LIBRARY.',
          ),
        ),
      );
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('IMPORT FAILED: $error');
    } finally {
      if (mounted) setState(() => importing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  List<Book> _filtered(List<Book> books) {
    final value = switch (shelf) {
      _Shelf.wantToRead => 'wantToRead',
      _Shelf.currentlyReading => 'currentlyReading',
      _Shelf.finished => 'finished',
      _Shelf.all => null,
    };
    return books.where((book) {
      final matchesShelf = value == null || book.shelf == value;
      final normalizedQuery = query.trim().toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty ||
          book.title.toLowerCase().contains(normalizedQuery) ||
          book.author.toLowerCase().contains(normalizedQuery);
      return matchesShelf && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksProvider);
    return Scaffold(
      appBar: BrutalAppBar(
        title: 'Bookmunity',
        actions: [
          IconButton(
            tooltip: grid ? 'LIST VIEW' : 'GRID VIEW',
            onPressed: () => setState(() => grid = !grid),
            icon: Text(grid ? 'LIST' : 'GRID'),
          ),
          IconButton(
            tooltip: 'READING STATS',
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const StatsScreen())),
            icon: const Text('STATS'),
          ),
          IconButton(
            tooltip: 'SETTINGS',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Text('SET'),
          ),
          IconButton(onPressed: _import, icon: const Text('+')),
        ],
      ),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('LIBRARY ERROR: $error')),
        data: (items) {
          final filtered = _filtered(items);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    labelText: 'SEARCH TITLE OR AUTHOR',
                    prefixText: '> ',
                  ),
                ),
              ),
              _ShelfBar(
                selected: shelf,
                onSelected: (value) => setState(() => shelf = value),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyLibrary(onImport: importing ? null : _import)
                    : grid
                    ? _BookGrid(books: filtered)
                    : _BookList(books: filtered),
              ),
            ],
          );
        },
      ),
      floatingActionButton: importing
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            )
          : null,
    );
  }
}

class _ShelfBar extends StatelessWidget {
  const _ShelfBar({required this.selected, required this.onSelected});

  final _Shelf selected;
  final ValueChanged<_Shelf> onSelected;

  @override
  Widget build(BuildContext context) {
    final labels = {
      _Shelf.all: 'ALL',
      _Shelf.wantToRead: 'WANT TO READ',
      _Shelf.currentlyReading: 'READING',
      _Shelf.finished: 'FINISHED',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: labels.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: BrutalChip(
                  label: entry.value,
                  selected: selected == entry.key,
                  onPressed: () => onSelected(entry.key),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onImport});

  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BrutalCard(
          backgroundColor: BrutalColors.yellow,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NO BOOKS.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Text('IMPORT ONE.'),
              const SizedBox(height: 20),
              BrutalPressable(
                onPressed: onImport,
                child: const Text('IMPORT +'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  const _BookGrid({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
        childAspectRatio: .65,
      ),
      itemCount: books.length,
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: books[index]),
          ),
        ),
        child: _BookTile(book: books[index]),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, index) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: books[index]),
          ),
        ),
        child: _BookTile(book: books[index], compact: true),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book, this.compact = false});

  final Book book;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cover = Container(
      height: compact ? 100 : 190,
      width: compact ? 72 : double.infinity,
      decoration: BoxDecoration(
        color: _coverColor(book.title),
        border: Border.all(color: BrutalColors.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: BrutalColors.ink, offset: Offset(4, 4)),
        ],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        book.title.toUpperCase(),
        maxLines: 5,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        BrutalProgressBar(value: book.progressPercent / 100),
        Text('${book.progressPercent.round()}%'),
      ],
    );
    return compact
        ? Row(
            children: [
              cover,
              const SizedBox(width: 16),
              Expanded(child: details),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cover),
              const SizedBox(height: 10),
              details,
            ],
          );
  }

  Color _coverColor(String title) {
    const colors = [
      BrutalColors.yellow,
      BrutalColors.blue,
      BrutalColors.pink,
      BrutalColors.green,
      BrutalColors.red,
    ];
    return colors[title.hashCode.abs() % colors.length];
  }
}
