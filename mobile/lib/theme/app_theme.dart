import 'package:flutter/material.dart';

/// AquaCare's compact, high-contrast ocean theme.
///
/// The theme borrows the restrained surfaces, typography hierarchy, and
/// consistent component treatment of GymMane and Streak while retaining
/// AquaCare's own lagoon/reef palette.
class AppTheme {
  static const Color _lagoon = Color(0xFF35D6C3);
  static const Color _deepOcean = Color(0xFF081B25);
  static const Color _reefSurface = Color(0xFF102C38);
  static const Color _lightCanvas = Color(0xFFF2F8F7);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? _lagoon : const Color(0xFF087F83);
    final canvas = isDark ? _deepOcean : _lightCanvas;
    final surface = isDark ? _reefSurface : _lightSurface;
    final card = isDark ? const Color(0xFF143744) : const Color(0xFFFFFFFF);
    final border = isDark ? const Color(0xFF28505D) : const Color(0xFFD7E7E4);
    final text = isDark ? const Color(0xFFEAF8F6) : const Color(0xFF17343A);
    final muted = isDark ? const Color(0xFFAAC2C3) : const Color(0xFF60777A);
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      surface: surface,
    );
    final scheme = base.copyWith(
      primary: primary,
      onPrimary: isDark ? const Color(0xFF062329) : Colors.white,
      secondary: isDark ? const Color(0xFF8BE8DC) : const Color(0xFF287E81),
      tertiary: const Color(0xFF62B9D3),
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      surfaceContainerLowest: canvas,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: isDark ? const Color(0xFF1B414D) : const Color(0xFFE8F1EF),
      surfaceContainerHighest: isDark ? const Color(0xFF234B57) : const Color(0xFFDCEAE7),
      outline: muted,
      outlineVariant: border,
      error: isDark ? const Color(0xFFFF8D83) : const Color(0xFFB3261E),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 21,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border.withValues(alpha: 0.8)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: isDark ? 0.20 : 0.13),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? primary : muted,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
            size: 22,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      dividerColor: border,
    );
  }
}
