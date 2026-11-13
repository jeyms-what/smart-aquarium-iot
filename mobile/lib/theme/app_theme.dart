import 'package:flutter/material.dart';

class AppTheme {
  static const Color _lagoon = Color(0xFF35D6C3);
  static const Color _deepOcean = Color(0xFF071A25);
  static const Color _midnightReef = Color(0xFF0D2B38);
  static const Color _seafoam = Color(0xFFB8FFF0);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF087F83),
      brightness: Brightness.light,
      surface: const Color(0xFFEAF7F5),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFEAF7F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFEAF7F5),
        foregroundColor: Color(0xFF102F38),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFF102F38), fontSize: 18, fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFEAF7F5).withValues(alpha: 0.88),
        indicatorColor: const Color(0xFFC2F3E9),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(color: const Color(0xFF17434A), fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500),
        ),
      ),
      dividerColor: const Color(0xFFCFE5E1),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _lagoon,
      brightness: Brightness.dark,
      surface: _midnightReef,
    ).copyWith(
      primary: _lagoon,
      secondary: _seafoam,
      tertiary: const Color(0xFF72DDF5),
      surface: _midnightReef,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: _deepOcean,
      appBarTheme: const AppBarTheme(
        backgroundColor: _deepOcean,
        foregroundColor: Color(0xFFE9FFFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFFE9FFFC), fontSize: 18, fontWeight: FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _midnightReef.withValues(alpha: 0.94),
        indicatorColor: const Color(0xFF145B61),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(color: const Color(0xFFE9FFFC), fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500),
        ),
      ),
      dividerColor: const Color(0xFF234954),
    );
  }
}
