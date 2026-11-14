import 'package:flutter/material.dart';

import '../../../providers/settings_providers.dart';

/// Colours for the reader surface. They must match `THEMES` in
/// assets/reader/reader.js so Flutter chrome blends into the page.
class ReaderPalette {
  const ReaderPalette({
    required this.background,
    required this.foreground,
    required this.muted,
    required this.panel,
    required this.isDark,
  });

  factory ReaderPalette.of(ReaderTheme theme) => switch (theme) {
    ReaderTheme.light => const ReaderPalette(
      background: Color(0xFFF7F4EE),
      foreground: Color(0xFF2B2B2B),
      muted: Color(0xFF8A857C),
      panel: Color(0xFFFFFDF9),
      isDark: false,
    ),
    ReaderTheme.sepia => const ReaderPalette(
      background: Color(0xFFF1E7D0),
      foreground: Color(0xFF4A3B2A),
      muted: Color(0xFF8E7B62),
      panel: Color(0xFFF8F0DE),
      isDark: false,
    ),
    ReaderTheme.dark => const ReaderPalette(
      background: Color(0xFF1C1B19),
      foreground: Color(0xFFDAD5CB),
      muted: Color(0xFF8C877E),
      panel: Color(0xFF262522),
      isDark: true,
    ),
  };

  final Color background;
  final Color foreground;
  final Color muted;
  final Color panel;
  final bool isDark;
}

/// Highlight swatches. Index is persisted in `Highlights.color` and must
/// match `HIGHLIGHT_COLORS` in reader.js.
const highlightSwatches = <Color>[
  Color(0xFFF2D16B),
  Color(0xFF9CCB9E),
  Color(0xFF9DB9E0),
  Color(0xFFE8A9C4),
];

const highlightSwatchNames = ['Yellow', 'Green', 'Blue', 'Pink'];

Color highlightSwatch(int index) =>
    highlightSwatches[index.clamp(0, highlightSwatches.length - 1)];
