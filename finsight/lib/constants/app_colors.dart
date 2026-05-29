import 'package:flutter/material.dart';

class AppColors {
  static const main = Color(0xFF008C89);
  static const dark = Color(0xFF004C4A);
  static const accent = Color(0xFF27C7B8);
  static const light = Color(0xFFEAF8F6);
  static const text = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFD6EEEA);
  static const red = Color(0xFFE94F37);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.main,
        primary: AppColors.main,
        secondary: AppColors.accent,
        surface: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
