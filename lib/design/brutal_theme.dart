import 'package:flutter/material.dart';

abstract final class BrutalColors {
  static const paper = Color(0xFFF4F0E6);
  static const ink = Color(0xFF0A0A0A);
  static const yellow = Color(0xFFFFE500);
  static const red = Color(0xFFFF3B30);
  static const blue = Color(0xFF2F5BFF);
  static const green = Color(0xFF00C46A);
  static const pink = Color(0xFFFF8AD8);
}

ThemeData brutalTheme({required bool dark}) {
  final background = dark ? BrutalColors.ink : BrutalColors.paper;
  final foreground = dark ? BrutalColors.paper : BrutalColors.ink;

  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: BrutalColors.yellow,
      onPrimary: BrutalColors.ink,
      secondary: BrutalColors.blue,
      onSecondary: BrutalColors.paper,
      error: BrutalColors.red,
      onError: BrutalColors.paper,
      surface: background,
      onSurface: foreground,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: foreground, width: 3)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: background,
      labelStyle: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
      hintStyle: TextStyle(color: foreground.withValues(alpha: 0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: foreground, width: 3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: foreground, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: BrutalColors.yellow, width: 3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: BrutalColors.red, width: 3),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        color: foreground,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1,
      ),
      headlineSmall: TextStyle(
        color: foreground,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
      bodyLarge: TextStyle(color: foreground, fontSize: 16),
      bodyMedium: TextStyle(color: foreground, fontSize: 14),
      labelLarge: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
  );
}
