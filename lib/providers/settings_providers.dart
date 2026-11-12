import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, ReaderSettings>((ref) {
      return SettingsNotifier()..load();
    });

class ReaderSettings {
  const ReaderSettings({this.fontSize = 20, this.lineHeight = 1.7});

  final double fontSize;
  final double lineHeight;

  ReaderSettings copyWith({double? fontSize, double? lineHeight}) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }
}

class SettingsNotifier extends StateNotifier<ReaderSettings> {
  SettingsNotifier() : super(const ReaderSettings());

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    state = state.copyWith(
      fontSize: preferences.getDouble('reader_font_size') ?? 20,
      lineHeight: preferences.getDouble('reader_line_height') ?? 1.7,
    );
  }

  Future<void> update(ReaderSettings next) async {
    state = next;
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setDouble('reader_font_size', next.fontSize),
      preferences.setDouble('reader_line_height', next.lineHeight),
    ]);
  }
}
