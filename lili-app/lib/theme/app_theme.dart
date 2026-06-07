import 'package:flutter/material.dart';

class AppTheme {
  static const deepNight    = Color(0xFF0D0D1A);
  static const nightSurface = Color(0xFF161628);
  static const cardBg       = Color(0xFF1E1832);
  static const rosePink     = Color(0xFFFF6B9D);
  static const softLavender = Color(0xFFC9B8FF);
  static const warmWhite    = Color(0xFFFFF5F8);
  static const dimWhite     = Color(0xFFB0A8C0);
  static const ahmedBubble  = Color(0xFF4A1A35);
  static const liliBubble   = Color(0xFF2A1F4A);

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: rosePink,
      onPrimary: Colors.white,
      secondary: softLavender,
      onSecondary: Colors.white,
      surface: nightSurface,
      onSurface: warmWhite,
    ),
    scaffoldBackgroundColor: deepNight,
    cardTheme: const CardTheme(color: cardBg),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3A2A4A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3A2A4A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: rosePink, width: 2),
      ),
      labelStyle: const TextStyle(color: dimWhite),
      hintStyle: const TextStyle(color: dimWhite),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: rosePink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: softLavender),
    ),
  );
}
