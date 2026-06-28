import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        tertiary: AppColors.lightTertiary,
        surface: AppColors.lightNeutral,
        background: AppColors.lightNeutral,
      ),
      scaffoldBackgroundColor: AppColors.lightNeutral,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.lightPrimary,
      ),
      cardTheme: const CardThemeData(color: Colors.white),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkTertiary,
        surface: Color(0xff1E1E1E), // Slightly lighter than neutral for card depth
        background: AppColors.darkNeutral,
      ),
      scaffoldBackgroundColor: AppColors.darkNeutral,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xff1E1E1E),
        foregroundColor: AppColors.darkPrimary,
      ),
      cardTheme: const CardThemeData(color: Color(0xff1E1E1E)),
    );
  }
}