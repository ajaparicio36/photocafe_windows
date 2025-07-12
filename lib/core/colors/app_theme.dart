import 'package:flutter/material.dart';
import 'package:photocafe_windows/core/colors/colors.dart';

class AppTheme {
  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'PlusJakartaSans',
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightPrimaryForeground,
      secondary: AppColors.lightSecondary,
      onSecondary: AppColors.lightSecondaryForeground,
      surface: AppColors.lightCard,
      onSurface: AppColors.lightCardForeground,
      background: AppColors.lightBackground,
      onBackground: AppColors.lightForeground,
      error: AppColors.lightDestructive,
      onError: AppColors.lightDestructiveForegound,
      outline: AppColors.lightBorder,
      surfaceVariant: AppColors.lightMuted,
      onSurfaceVariant: AppColors.lightMutedForeground,
    ),
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardTheme: const CardThemeData(
      color: AppColors.lightCard,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.touchPrimary,
        foregroundColor: AppColors.lightPrimaryForeground,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBackground,
      foregroundColor: AppColors.lightForeground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.lightForeground,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.lightForeground,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        fontFamily: 'PlusJakartaSans',
      ),
      headlineMedium: TextStyle(
        color: AppColors.lightForeground,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFamily: 'PlusJakartaSans',
      ),
      bodyLarge: TextStyle(
        color: AppColors.lightForeground,
        fontSize: 18,
        fontFamily: 'PlusJakartaSans',
      ),
      bodyMedium: TextStyle(
        color: AppColors.lightMutedForeground,
        fontSize: 16,
        fontFamily: 'PlusJakartaSans',
      ),
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'PlusJakartaSans',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkPrimaryForeground,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkSecondaryForeground,
      surface: AppColors.darkCard,
      onSurface: AppColors.darkCardForeground,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkForeground,
      error: AppColors.darkDestructive,
      onError: AppColors.darkDestructiveForegound,
      outline: AppColors.darkBorder,
      surfaceVariant: AppColors.darkMuted,
      onSurfaceVariant: AppColors.darkMutedForeground,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardTheme: const CardThemeData(
      color: AppColors.darkCard,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.darkPrimaryForeground,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInput,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkForeground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.darkForeground,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.darkForeground,
        fontSize: 40,
        fontWeight: FontWeight.bold,
        fontFamily: 'PlusJakartaSans',
      ),
      headlineMedium: TextStyle(
        color: AppColors.darkForeground,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        fontFamily: 'PlusJakartaSans',
      ),
      bodyLarge: TextStyle(
        color: AppColors.darkForeground,
        fontSize: 18,
        fontFamily: 'PlusJakartaSans',
      ),
      bodyMedium: TextStyle(
        color: AppColors.darkMutedForeground,
        fontSize: 16,
        fontFamily: 'PlusJakartaSans',
      ),
    ),
  );
}
