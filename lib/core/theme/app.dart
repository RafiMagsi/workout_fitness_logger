import 'package:flutter/material.dart';

/// App theme: Apple Fitness-inspired dark UI with authentic Activity ring
/// colors (Apple Human Interface Guidelines: Move rgb(250, 17, 79),
/// Exercise rgb(166, 233, 48), Stand rgb(30, 228, 225)) plus 2026-era
/// "liquid glass" surface tokens used by the shell, cards, and charts.
class AppTheme {
  AppTheme._();

  // ---- Canvas & surfaces -------------------------------------------------
  static const _bg = Color(0xFF050508);
  static const _surface = Color(0xFF121218);
  static const _surfaceRaised = Color(0xFF1C1C24);
  static const _border = Color(0xFF2A2A35);

  // ---- Text ---------------------------------------------------------------
  static const _textPrimary = Color(0xFFF5F5F7);
  static const _textSecondary = Color(0xFF9E9EA7);
  static const _textTertiary = Color(0xFF6A6A73);

  // ---- Activity rings (authentic Apple HIG values) -------------------------
  static const _move = Color(0xFFFA114F);
  static const _exercise = Color(0xFF92E82A);
  static const _stand = Color(0xFF1EE4E1);

  // ---- Supporting palette --------------------------------------------------
  static const _accent = Color(0xFF0A84FF);
  static const _purple = Color(0xFFBF5AF2);
  static const _orange = Color(0xFFFF9F0A);
  static const _red = Color(0xFFFF453A);
  static const _blue = Color(0xFF0A84FF);
  static const _green = Color(0xFF30D158);

  static final Color moveSoft = _move.withValues(alpha: 0.16);
  static final Color exerciseSoft = _exercise.withValues(alpha: 0.16);
  static final Color standSoft = _stand.withValues(alpha: 0.16);
  static final Color accentSoft = _accent.withValues(alpha: 0.14);
  static final Color greenSoft = _green.withValues(alpha: 0.16);
  static final Color orangeSoft = _orange.withValues(alpha: 0.16);
  static final Color redSoft = _red.withValues(alpha: 0.16);

  /// Sheen gradient used on hero cards ("liquid glass" highlight).
  static const LinearGradient glassSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x14FFFFFF), Color(0x00FFFFFF), Color(0x0AFFFFFF)],
    stops: [0.0, 0.45, 1.0],
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bg,
    colorScheme: const ColorScheme.dark(
      primary: _accent,
      secondary: _purple,
      tertiary: _stand,
      surface: _surface,
      onSurface: _textPrimary,
      outline: _border,
      error: _red,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.05,
        letterSpacing: -0.8,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.08,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.1,
        letterSpacing: -0.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        height: 1.12,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        height: 1.15,
      ),
      headlineSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
        height: 1.25,
      ),
      titleSmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
        height: 1.3,
        letterSpacing: 0.2,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: _textPrimary,
        height: 1.35,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: _textPrimary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: _textSecondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
        height: 1.25,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _textSecondary,
        height: 1.3,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _textTertiary,
        height: 1.3,
        letterSpacing: 0.4,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: _textSecondary, size: 22),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: _border,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: _textSecondary, size: 22),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _red, width: 1),
      ),
      hintStyle: const TextStyle(color: _textTertiary),
      labelStyle: const TextStyle(color: _textTertiary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _accent,
        side: const BorderSide(color: _accent, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _accent,
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _surfaceRaised,
      contentTextStyle: const TextStyle(color: _textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      activeTrackColor: _accent,
      inactiveTrackColor: _border,
      thumbColor: _accent,
      overlayColor: _accent.withValues(alpha: 0.18),
      valueIndicatorColor: _surfaceRaised,
      valueIndicatorTextStyle: const TextStyle(
        color: _textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _accent;
        return const Color(0xFF8E8E93);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accentSoft;
        return _border;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _accent,
      circularTrackColor: _border,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _textPrimary,
      unselectedLabelColor: _textTertiary,
      indicatorColor: _accent,
      dividerColor: Colors.transparent,
    ),
  );

  // ---- Exposed tokens ------------------------------------------------------
  // Rings (authentic Apple Activity colors).
  static Color get move => _move;
  static Color get exercise => _exercise;
  static Color get stand => _stand;

  // Supporting palette.
  static Color get accent => _accent;
  static Color get green => _green;
  static Color get orange => _orange;
  static Color get red => _red;
  static Color get purple => _purple;
  static Color get blue => _blue;

  // Surfaces & text.
  static Color get surface => _surface;
  static Color get surfaceRaised => _surfaceRaised;
  static Color get border => _border;
  static Color get textPrimary => _textPrimary;
  static Color get textSecondary => _textSecondary;
  static Color get textTertiary => _textTertiary;
  static Color get bg => _bg;
}
