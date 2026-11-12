import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../providers/app_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    return Scaffold(
      appBar: const BrutalAppBar(title: 'Reading Stats'),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('STATS ERROR: $error')),
        data: (items) {
          final finished = items.where((book) => book.isFinished).length;
          final reading = items
              .where((book) => book.shelf == 'currentlyReading')
              .length;
          final progress = items.isEmpty
              ? 0
              : items
                        .map((book) => book.progressPercent)
                        .reduce((a, b) => a + b) /
                    items.length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'YOUR READING DASHBOARD',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              _StatCard(
                label: 'BOOKS IN LIBRARY',
                value: '${items.length}',
                color: BrutalColors.yellow,
              ),
              _StatCard(
                label: 'CURRENTLY READING',
                value: '$reading',
                color: BrutalColors.blue,
              ),
              _StatCard(
                label: 'BOOKS FINISHED',
                value: '$finished',
                color: BrutalColors.green,
              ),
              _StatCard(
                label: 'AVERAGE PROGRESS',
                value: '${progress.round()}%',
                color: BrutalColors.pink,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: BrutalCard(
        backgroundColor: color,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Text(value, style: Theme.of(context).textTheme.headlineLarge),
          ],
        ),
      ),
    );
  }
}
