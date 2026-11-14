import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../design/brutal_theme.dart';
import '../../../design/brutal_widgets.dart';
import '../../../design/formatters.dart';
import '../../../providers/app_providers.dart';
import '../../achievements/data/achievement_service.dart';
import '../../achievements/domain/achievement_calculator.dart';
import '../../achievements/domain/badges.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(booksProvider);
    final summary = ref.watch(achievementSummaryProvider);
    final unlocks = ref.watch(badgeUnlocksProvider);
    return Scaffold(
      appBar: const BrutalAppBar(title: 'Reading stats'),
      body: switch ((books, summary)) {
        (AsyncData(value: final items), AsyncData(value: final result)) =>
          _StatsBody(
            books: items,
            summary: result,
            unlocks: {
              for (final unlock in unlocks.valueOrNull ?? const <BadgeUnlock>[])
                unlock.badgeId: unlock.unlockedAt,
            },
          ),
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => EmptyState(
          icon: Icons.error_outline,
          title: 'Stats could not be loaded',
          message: '$error',
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({
    required this.books,
    required this.summary,
    required this.unlocks,
  });

  final List<Book> books;
  final AchievementSummary summary;
  final Map<String, DateTime> unlocks;

  @override
  Widget build(BuildContext context) {
    final reading = books
        .where((book) => book.shelf == 'currentlyReading')
        .length;
    final visibleBadges = Badges.all
        .where(
          (badge) =>
              !badge.hiddenUntilAvailable ||
              summary.genresKnown ||
              unlocks.containsKey(badge.id),
        )
        .toList();
    final earnedCount = visibleBadges
        .where((badge) => unlocks.containsKey(badge.id))
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _StreakCard(summary: summary),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.9,
          children: [
            _StatTile(
              label: 'Books finished',
              value: '${summary.finishedBooks}',
              icon: Icons.check_circle_outline,
            ),
            _StatTile(
              label: 'Reading now',
              value: '$reading',
              icon: Icons.menu_book_outlined,
            ),
            _StatTile(
              label: 'Time reading',
              value: formatDuration(summary.totalReadingTime),
              icon: Icons.schedule,
            ),
            _StatTile(
              label: 'In library',
              value: '${books.length}',
              icon: Icons.local_library_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _WeekStrip(days: summary.readingDays),
        const SizedBox(height: 28),
        SectionLabel(
          'Badges',
          trailing: Text(
            '$earnedCount of ${visibleBadges.length}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        for (final category in BadgeCategory.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text(
              category.label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
            children: [
              for (final badge in visibleBadges.where(
                (badge) => badge.category == category,
              ))
                _BadgeTile(
                  badge: badge,
                  unlockedAt: unlocks[badge.id],
                  progress: summary.progress[badge.id]!,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.summary});

  final AchievementSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = summary.currentStreak;
    return BrutalCard(
      backgroundColor: BrutalColors.yellow,
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current == 0
                      ? 'No streak yet'
                      : '$current day${current == 1 ? '' : 's'} in a row',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: BrutalColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  current == 0
                      ? 'Read for a minute today to start one.'
                      : 'Longest streak: ${summary.longestStreak} '
                            'day${summary.longestStreak == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: BrutalColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});

  final Set<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return BrutalCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 days', style: theme.textTheme.labelMedium),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var offset = 6; offset >= 0; offset--)
                () {
                  final day = DateTime(
                    today.year,
                    today.month,
                    today.day - offset,
                  );
                  final read = days.contains(day);
                  return Semantics(
                    label:
                        '${formatDate(day)}: ${read ? 'read' : 'did not read'}',
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: read
                                ? BrutalColors.green
                                : theme.colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: offset == 0
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.outlineVariant,
                              width: offset == 0 ? 1.5 : 1,
                            ),
                          ),
                          child: read
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[day.weekday - 1],
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }(),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BrutalCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: theme.textTheme.titleLarge),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.unlockedAt,
    required this.progress,
  });

  final BadgeDefinition badge;
  final DateTime? unlockedAt;
  final BadgeProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final earned = unlockedAt != null;
    final accent = switch (badge.category) {
      BadgeCategory.completion => BrutalColors.blue,
      BadgeCategory.streak => BrutalColors.red,
      BadgeCategory.progress => BrutalColors.green,
    };
    return Semantics(
      label:
          '${badge.title}. ${badge.description}. '
          '${earned ? 'Earned ${formatDate(unlockedAt!)}' : 'Locked'}',
      child: InkWell(
        borderRadius: BrutalTokens.borderRadius,
        onTap: () => _showDetails(context, accent),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BrutalTokens.borderRadius,
            border: Border.all(
              color: earned
                  ? theme.colorScheme.outline
                  : theme.colorScheme.outlineVariant,
            ),
            color: earned ? accent.withValues(alpha: 0.12) : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: earned ? 1 : 0.35,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: earned
                      ? accent
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    badge.icon,
                    color: earned ? Colors.white : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: earned
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              if (!earned)
                BrutalProgressBar(
                  value: progress.fraction,
                  height: 4,
                  color: accent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Color accent) {
    final theme = Theme.of(context);
    final earned = unlockedAt != null;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: earned
                    ? accent
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  badge.icon,
                  size: 32,
                  color: earned ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(badge.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(badge.description, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                earned
                    ? 'Earned on ${formatDate(unlockedAt!)}'
                    : 'Progress: ${progress.current.clamp(0, progress.target)} of ${progress.target}',
                style: theme.textTheme.labelMedium,
              ),
              if (!earned) ...[
                const SizedBox(height: 8),
                BrutalProgressBar(value: progress.fraction, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
