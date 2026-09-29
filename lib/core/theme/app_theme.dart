import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1E3A8A);      // Deep blue
  static const Color accent  = Color(0xFFF59E0B);      // Amber
  static const Color surface = Color(0xFFF9FAFB);      // Light gray
  static const Color error   = Color(0xFFDC2626);      // Red

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: surface,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
}