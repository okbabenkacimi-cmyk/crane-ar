import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color surface = Color(0xFF12151A);
  static const Color surfaceRaised = Color(0xFF1B2027);
  static const Color accent = Color(0xFFFFB300);
  static const Color secondary = Color(0xFF35C2FF);
  static const Color danger = Color(0xFFFF5252);
  static const Color success = Color(0xFF4CD964);

  static ThemeData dark() {
    final ThemeData base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: surface,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: secondary,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Colors.white,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
