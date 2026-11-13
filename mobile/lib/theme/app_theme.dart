import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seed = Color(0xFF12B8B0);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF4F9F9),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF4F9F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F9F9),
        foregroundColor: Color(0xFF102B32),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFF102B32), fontSize: 18, fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFD9F5F0),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500),
        ),
      ),
      dividerColor: const Color(0xFFE2ECEC),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
      surface: const Color(0xFF111F27),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF09151C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF09151C),
        foregroundColor: Color(0xFFEAF7F6),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFFEAF7F6), fontSize: 18, fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF101F28),
        indicatorColor: const Color(0xFF174A50),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(color: const Color(0xFFEAF7F6), fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500),
        ),
      ),
      dividerColor: const Color(0xFF243A43),
    );
  }
}
