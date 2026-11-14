import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, ReaderSettings>((ref) {
      return SettingsNotifier()..load();
    });

final appThemeModeProvider =
    StateNotifierProvider<AppThemeModeNotifier, ThemeMode>((ref) {
      return AppThemeModeNotifier()..load();
    });

enum ReaderFlow { paginated, scrolled }

enum ReaderTheme { light, sepia, dark }

enum ReaderFont { serif, sans }

enum ReaderOrientation { auto, portrait, landscape }

class ReaderSettings {
  const ReaderSettings({
    this.fontSize = 19,
    this.lineHeight = 1.6,
    this.margin = 20,
    this.theme = ReaderTheme.light,
    this.flow = ReaderFlow.paginated,
    this.font = ReaderFont.serif,
    this.keepScreenAwake = true,
    this.orientation = ReaderOrientation.auto,
  });

  static const minFontSize = 14.0;
  static const maxFontSize = 30.0;
  static const minLineHeight = 1.2;
  static const maxLineHeight = 2.2;
  static const minMargin = 8.0;
  static const maxMargin = 48.0;

  final double fontSize;
  final double lineHeight;
  final double margin;
  final ReaderTheme theme;
  final ReaderFlow flow;
  final ReaderFont font;
  final bool keepScreenAwake;
  final ReaderOrientation orientation;

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? margin,
    ReaderTheme? theme,
    ReaderFlow? flow,
    ReaderFont? font,
    bool? keepScreenAwake,
    ReaderOrientation? orientation,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      margin: margin ?? this.margin,
      theme: theme ?? this.theme,
      flow: flow ?? this.flow,
      font: font ?? this.font,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      orientation: orientation ?? this.orientation,
    );
  }

  /// The shape the JavaScript reader expects.
  Map<String, Object> toReaderJson() => {
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'margin': margin,
    'theme': theme.name,
    'flow': flow.name,
    'font': font.name,
  };

  @override
  bool operator ==(Object other) =>
      other is ReaderSettings &&
      other.fontSize == fontSize &&
      other.lineHeight == lineHeight &&
      other.margin == margin &&
      other.theme == theme &&
      other.flow == flow &&
      other.font == font &&
      other.keepScreenAwake == keepScreenAwake &&
      other.orientation == orientation;

  @override
  int get hashCode => Object.hash(
    fontSize,
    lineHeight,
    margin,
    theme,
    flow,
    font,
    keepScreenAwake,
    orientation,
  );
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

class SettingsNotifier extends StateNotifier<ReaderSettings> {
  SettingsNotifier() : super(const ReaderSettings());

  static const _fontSize = 'reader_font_size';
  static const _lineHeight = 'reader_line_height';
  static const _margin = 'reader_margin';
  static const _theme = 'reader_theme';
  static const _flow = 'reader_flow';
  static const _font = 'reader_font';
  static const _keepAwake = 'reader_keep_awake';
  static const _orientation = 'reader_orientation';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    const defaults = ReaderSettings();
    if (!mounted) return;
    state = ReaderSettings(
      fontSize: (preferences.getDouble(_fontSize) ?? defaults.fontSize).clamp(
        ReaderSettings.minFontSize,
        ReaderSettings.maxFontSize,
      ),
      lineHeight: (preferences.getDouble(_lineHeight) ?? defaults.lineHeight)
          .clamp(ReaderSettings.minLineHeight, ReaderSettings.maxLineHeight),
      margin: (preferences.getDouble(_margin) ?? defaults.margin).clamp(
        ReaderSettings.minMargin,
        ReaderSettings.maxMargin,
      ),
      theme: _enumByName(
        ReaderTheme.values,
        preferences.getString(_theme),
        defaults.theme,
      ),
      flow: _enumByName(
        ReaderFlow.values,
        preferences.getString(_flow),
        defaults.flow,
      ),
      font: _enumByName(
        ReaderFont.values,
        preferences.getString(_font),
        defaults.font,
      ),
      keepScreenAwake:
          preferences.getBool(_keepAwake) ?? defaults.keepScreenAwake,
      orientation: _enumByName(
        ReaderOrientation.values,
        preferences.getString(_orientation),
        defaults.orientation,
      ),
    );
  }

  Future<void> update(ReaderSettings next) async {
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setDouble(_fontSize, next.fontSize),
      preferences.setDouble(_lineHeight, next.lineHeight),
      preferences.setDouble(_margin, next.margin),
      preferences.setString(_theme, next.theme.name),
      preferences.setString(_flow, next.flow.name),
      preferences.setString(_font, next.font.name),
      preferences.setBool(_keepAwake, next.keepScreenAwake),
      preferences.setString(_orientation, next.orientation.name),
    ]);
  }
}

class AppThemeModeNotifier extends StateNotifier<ThemeMode> {
  AppThemeModeNotifier() : super(ThemeMode.system);

  static const _key = 'app_theme_mode';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = _enumByName(
      ThemeMode.values,
      preferences.getString(_key),
      ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, mode.name);
  }
}
