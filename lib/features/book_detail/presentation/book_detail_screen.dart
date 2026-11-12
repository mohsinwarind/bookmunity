import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';
import '../../highlights/presentation/highlights_screen.dart';
import '../../reader/presentation/reader_screen.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({required this.book, super.key});

  final Book book;

  Future<void> _changeShelf(
    BuildContext context,
    WidgetRef ref,
    String shelf,
  ) async {
    final database = await ref.read(databaseProvider.future);
    await database.updateShelf(book, shelf);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = <String, String>{
      'SHELF': book.shelf.toUpperCase(),
      'AUTHOR': book.author.toUpperCase(),
      'READ': '${book.progressPercent.round()}% COMPLETE',
      'ADDED': book.addedAt.toLocal().toString().split(' ').first,
    };

    return Scaffold(
      appBar: BrutalAppBar(
        title: book.title,
        actions: [
          IconButton(
            tooltip: 'REFRESH METADATA',
            onPressed: () async {
              try {
                final service = await ref.read(importServiceProvider.future);
                await service.refreshMetadata(book);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('METADATA REFRESHED.')),
                  );
                }
              } on FormatException catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error.message)));
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('REFRESH FAILED: $error')),
                  );
                }
              }
            },
            icon: const Text('META'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrutalCard(
                backgroundColor: BrutalColors.yellow,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 110,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: BrutalColors.ink, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: BrutalColors.ink,
                            offset: Offset(4, 4),
                          ),
                        ],
                        color: _coverColor(book.title),
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        book.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title.toUpperCase(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(book.author.toUpperCase()),
                          const SizedBox(height: 14),
                          BrutalProgressBar(value: book.progressPercent / 100),
                          const SizedBox(height: 10),
                          Text('${book.progressPercent.round()}% complete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  BrutalPressable(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReaderScreen(book: book),
                        ),
                      );
                    },
                    backgroundColor: BrutalColors.blue,
                    foregroundColor: BrutalColors.paper,
                    child: const Text('READ NOW'),
                  ),
                  BrutalPressable(
                    onPressed: () =>
                        _changeShelf(context, ref, 'currentlyReading'),
                    backgroundColor: BrutalColors.green,
                    child: const Text('START READING'),
                  ),
                  BrutalPressable(
                    onPressed: () => _changeShelf(context, ref, 'finished'),
                    backgroundColor: BrutalColors.pink,
                    child: const Text('MARK DONE'),
                  ),
                  BrutalPressable(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HighlightsScreen(book: book),
                      ),
                    ),
                    backgroundColor: BrutalColors.yellow,
                    child: const Text('HIGHLIGHTS'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'BOOK STATS',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ...metadata.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Expanded(flex: 2, child: Text(entry.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              BrutalPressable(
                onPressed: () async {
                  final database = await ref.read(databaseProvider.future);
                  await database.deleteBook(book);
                  if (context.mounted) Navigator.of(context).pop();
                },
                backgroundColor: BrutalColors.red,
                foregroundColor: BrutalColors.paper,
                child: const Text('DELETE BOOK'),
              ),
            ],
          ),
        ),
      ),
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
