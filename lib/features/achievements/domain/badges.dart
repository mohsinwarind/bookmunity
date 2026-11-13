import 'package:flutter/material.dart';

enum BadgeCategory { completion, streak, progress }

extension BadgeCategoryLabel on BadgeCategory {
  String get label => switch (this) {
    BadgeCategory.completion => 'Books finished',
    BadgeCategory.streak => 'Reading streaks',
    BadgeCategory.progress => 'Milestones',
  };
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
    required this.target,
    this.hiddenUntilAvailable = false,
  });

  /// Stable id persisted in the database and shared with friends. Never
  /// rename an id once released.
  final String id;
  final String title;
  final String description;
  final BadgeCategory category;
  final IconData icon;

  /// The count needed to earn the badge (books, days, highlights, ...).
  final int target;

  /// Shown only once the data it depends on exists (e.g. genres).
  final bool hiddenUntilAvailable;
}

abstract final class Badges {
  static const firstChapter = BadgeDefinition(
    id: 'first_chapter',
    title: 'First Chapter',
    description: 'Finish your first book',
    category: BadgeCategory.completion,
    icon: Icons.auto_stories_outlined,
    target: 1,
  );
  static const bookStarter = BadgeDefinition(
    id: 'book_starter',
    title: 'Book Starter',
    description: 'Finish 3 books',
    category: BadgeCategory.completion,
    icon: Icons.menu_book_outlined,
    target: 3,
  );
  static const bookworm = BadgeDefinition(
    id: 'bookworm',
    title: 'Bookworm',
    description: 'Finish 5 books',
    category: BadgeCategory.completion,
    icon: Icons.pest_control_outlined,
    target: 5,
  );
  static const avidReader = BadgeDefinition(
    id: 'avid_reader',
    title: 'Avid Reader',
    description: 'Finish 10 books',
    category: BadgeCategory.completion,
    icon: Icons.local_library_outlined,
    target: 10,
  );
  static const libraryLegend = BadgeDefinition(
    id: 'library_legend',
    title: 'Library Legend',
    description: 'Finish 25 books',
    category: BadgeCategory.completion,
    icon: Icons.account_balance_outlined,
    target: 25,
  );
  static const genreExplorer = BadgeDefinition(
    id: 'genre_explorer',
    title: 'Genre Explorer',
    description: 'Finish books from 5 different genres',
    category: BadgeCategory.completion,
    icon: Icons.explore_outlined,
    target: 5,
    hiddenUntilAvailable: true,
  );

  static const readingSpark = BadgeDefinition(
    id: 'reading_spark',
    title: 'Reading Spark',
    description: 'Read on 2 days in a row',
    category: BadgeCategory.streak,
    icon: Icons.bolt_outlined,
    target: 2,
  );
  static const steadyReader = BadgeDefinition(
    id: 'steady_reader',
    title: 'Steady Reader',
    description: 'Read on 3 days in a row',
    category: BadgeCategory.streak,
    icon: Icons.trending_up,
    target: 3,
  );
  static const weeklyReader = BadgeDefinition(
    id: 'weekly_reader',
    title: 'Weekly Reader',
    description: 'Read on 7 days in a row',
    category: BadgeCategory.streak,
    icon: Icons.date_range_outlined,
    target: 7,
  );
  static const dedicatedReader = BadgeDefinition(
    id: 'dedicated_reader',
    title: 'Dedicated Reader',
    description: 'Read on 14 days in a row',
    category: BadgeCategory.streak,
    icon: Icons.local_fire_department_outlined,
    target: 14,
  );
  static const readingHabit = BadgeDefinition(
    id: 'reading_habit',
    title: 'Reading Habit',
    description: 'Read on 30 days in a row',
    category: BadgeCategory.streak,
    icon: Icons.event_repeat_outlined,
    target: 30,
  );
  static const readingChampion = BadgeDefinition(
    id: 'reading_champion',
    title: 'Reading Champion',
    description: 'Read on 100 days in a row',
    category: BadgeCategory.streak,
    icon: Icons.emoji_events_outlined,
    target: 100,
  );

  static const firstSession = BadgeDefinition(
    id: 'first_session',
    title: 'First Session',
    description: 'Open a book and read for a minute',
    category: BadgeCategory.progress,
    icon: Icons.play_circle_outline,
    target: 1,
  );
  static const halfwayThere = BadgeDefinition(
    id: 'halfway_there',
    title: 'Halfway There',
    description: 'Reach 50% in a book',
    category: BadgeCategory.progress,
    icon: Icons.contrast,
    target: 50,
  );
  static const finisher = BadgeDefinition(
    id: 'finisher',
    title: 'Finisher',
    description: 'Reach 100% in a book',
    category: BadgeCategory.progress,
    icon: Icons.flag_outlined,
    target: 100,
  );
  static const comebackReader = BadgeDefinition(
    id: 'comeback_reader',
    title: 'Comeback Reader',
    description: 'Return to a book you left for 14+ days',
    category: BadgeCategory.progress,
    icon: Icons.replay,
    target: 1,
  );
  static const highlightCollector = BadgeDefinition(
    id: 'highlight_collector',
    title: 'Highlight Collector',
    description: 'Save 10 highlights',
    category: BadgeCategory.progress,
    icon: Icons.format_quote_outlined,
    target: 10,
  );

  static const all = <BadgeDefinition>[
    firstChapter,
    bookStarter,
    bookworm,
    avidReader,
    libraryLegend,
    genreExplorer,
    readingSpark,
    steadyReader,
    weeklyReader,
    dedicatedReader,
    readingHabit,
    readingChampion,
    firstSession,
    halfwayThere,
    finisher,
    comebackReader,
    highlightCollector,
  ];

  static BadgeDefinition? byId(String id) {
    for (final badge in all) {
      if (badge.id == id) return badge;
    }
    return null;
  }
}
