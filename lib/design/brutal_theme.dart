import 'package:flutter/material.dart';

/// Bookmunity palette.
///
/// The app keeps its neo-brutalist identity (solid outlines, offset shadows,
/// flat accent blocks) but in a calmer register: warm off-white instead of
/// stark paper, charcoal instead of pure black, muted accents, thinner lines.
abstract final class BrutalColors {
  static const paper = Color(0xFFF7F4EE);
  static const surface = Color(0xFFFFFDF9);
  static const ink = Color(0xFF2B2B2B);
  static const inkSoft = Color(0xFF6B6760);

  static const night = Color(0xFF1C1B19);
  static const nightSurface = Color(0xFF262522);
  static const nightInk = Color(0xFFE8E3D9);

  static const yellow = Color(0xFFF2D16B);
  static const red = Color(0xFFD46A5F);
  static const blue = Color(0xFF5B7DB1);
  static const green = Color(0xFF6FA58A);
  static const pink = Color(0xFFE3A6C0);

  /// Accents used for generated covers and highlight swatches.
  static const accents = [yellow, blue, pink, green, red];
}

/// Shape and line tokens shared by the custom widgets.
abstract final class BrutalTokens {
  static const borderWidth = 1.5;
  static const shadowOffset = Offset(2, 2);
  static const radius = 12.0;
  static const smallRadius = 8.0;
  static const borderRadius = BorderRadius.all(Radius.circular(radius));
  static const smallBorderRadius = BorderRadius.all(
    Radius.circular(smallRadius),
  );
}

ThemeData brutalTheme({required bool dark}) {
  final background = dark ? BrutalColors.night : BrutalColors.paper;
  final surface = dark ? BrutalColors.nightSurface : BrutalColors.surface;
  final foreground = dark ? BrutalColors.nightInk : BrutalColors.ink;
  final muted = dark ? const Color(0xFFA9A398) : BrutalColors.inkSoft;
  final outline = foreground.withValues(alpha: dark ? 0.55 : 0.85);
  final subtle = foreground.withValues(alpha: 0.12);

  OutlineInputBorder border(Color color, [double width = 1.5]) =>
      OutlineInputBorder(
        borderRadius: BrutalTokens.smallBorderRadius,
        borderSide: BorderSide(color: color, width: width),
      );

  final text = TextTheme(
    headlineLarge: TextStyle(
      color: foreground,
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.15,
    ),
    headlineSmall: TextStyle(
      color: foreground,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      color: foreground,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      color: foreground,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: TextStyle(
      color: foreground,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(color: foreground, fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(color: foreground, fontSize: 14, height: 1.4),
    bodySmall: TextStyle(color: muted, fontSize: 12.5, height: 1.35),
    labelLarge: TextStyle(
      color: foreground,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      color: muted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    labelSmall: TextStyle(color: muted, fontSize: 11, letterSpacing: 0.3),
  );

  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: BrutalColors.blue,
      onPrimary: Colors.white,
      secondary: BrutalColors.yellow,
      onSecondary: BrutalColors.ink,
      tertiary: BrutalColors.green,
      onTertiary: BrutalColors.ink,
      error: BrutalColors.red,
      onError: Colors.white,
      surface: background,
      onSurface: foreground,
      onSurfaceVariant: muted,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: subtle,
      outline: outline,
      outlineVariant: subtle,
    ),
    textTheme: text,
    iconTheme: IconThemeData(color: foreground),
    dividerTheme: DividerThemeData(color: subtle, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w500),
      floatingLabelStyle: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(outline),
      enabledBorder: border(outline),
      focusedBorder: border(BrutalColors.blue, 2),
      errorBorder: border(BrutalColors.red),
      focusedErrorBorder: border(BrutalColors.red, 2),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: BrutalColors.blue,
      inactiveTrackColor: subtle,
      thumbColor: BrutalColors.blue,
      overlayColor: BrutalColors.blue.withValues(alpha: 0.12),
      trackHeight: 3,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : foreground.withValues(alpha: 0.7),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? BrutalColors.green : subtle,
      ),
      trackOutlineColor: WidgetStateProperty.all(outline),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? BrutalColors.nightInk : BrutalColors.ink,
      contentTextStyle: TextStyle(
        color: dark ? BrutalColors.night : Colors.white,
        fontSize: 14,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BrutalTokens.smallBorderRadius,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: foreground.withValues(alpha: 0.25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BrutalTokens.borderRadius,
        side: BorderSide(color: outline, width: BrutalTokens.borderWidth),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BrutalTokens.smallBorderRadius,
        side: BorderSide(color: outline, width: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: dark ? BrutalColors.nightInk : BrutalColors.blue,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: BrutalColors.blue,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: foreground,
      textColor: foreground,
      subtitleTextStyle: text.bodySmall,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: foreground,
      unselectedLabelColor: muted,
      indicatorColor: BrutalColors.blue,
      dividerColor: subtle,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStateProperty.all(BorderSide(color: outline)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BrutalColors.blue
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : foreground,
        ),
      ),
    ),
  );
}
