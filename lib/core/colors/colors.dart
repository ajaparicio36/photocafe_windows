import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors (monochrome - black on white)
  static const Color lightBackground = Color(
    0xFFFFFFFF,
  ); // Pure white background
  static const Color lightForeground = Color(0xFF000000); // Pure black text
  static const Color lightCard = Color(0xFFFAFAFA); // Very light gray cards
  static const Color lightCardForeground = Color(
    0xFF000000,
  ); // Black text on cards
  static const Color lightPrimary = Color(0xFF000000); // Black primary
  static const Color lightPrimaryForeground = Color(
    0xFFFFFFFF,
  ); // White text on primary
  static const Color lightSecondary = Color(0xFFF5F5F5); // Light gray secondary
  static const Color lightSecondaryForeground = Color(
    0xFF000000,
  ); // Black text on secondary
  static const Color lightMuted = Color(0xFFF9F9F9); // Very light gray muted
  static const Color lightMutedForeground = Color(
    0xFF737373,
  ); // Medium gray text
  static const Color lightAccent = Color(0xFFF5F5F5); // Light gray accent
  static const Color lightAccentForeground = Color(
    0xFF000000,
  ); // Black text on accent
  static const Color lightBorder = Color(0xFFE5E5E5); // Light gray borders
  static const Color lightInput = Color(
    0xFFF5F5F5,
  ); // Light gray input background
  static const Color lightDestructive = Color(0xFF000000); // Black destructive
  static const Color lightDestructiveForegound = Color(
    0xFFFFFFFF,
  ); // White text on destructive

  // Dark theme colors (monochrome - white on black, reversed)
  static const Color darkBackground = Color(
    0xFF000000,
  ); // Pure black background
  static const Color darkForeground = Color(0xFFFFFFFF); // Pure white text
  static const Color darkCard = Color(0xFF0A0A0A); // Very dark gray cards
  static const Color darkCardForeground = Color(
    0xFFFFFFFF,
  ); // White text on cards
  static const Color darkPrimary = Color(0xFFFFFFFF); // White primary
  static const Color darkPrimaryForeground = Color(
    0xFF000000,
  ); // Black text on primary
  static const Color darkSecondary = Color(0xFF171717); // Dark gray secondary
  static const Color darkSecondaryForeground = Color(
    0xFFFFFFFF,
  ); // White text on secondary
  static const Color darkMuted = Color(0xFF0F0F0F); // Very dark gray muted
  static const Color darkMutedForeground = Color(
    0xFF8C8C8C,
  ); // Medium gray text
  static const Color darkAccent = Color(0xFF171717); // Dark gray accent
  static const Color darkAccentForeground = Color(
    0xFFFFFFFF,
  ); // White text on accent
  static const Color darkBorder = Color(0xFF2A2A2A); // Dark gray borders
  static const Color darkInput = Color(
    0xFF171717,
  ); // Dark gray input background
  static const Color darkDestructive = Color(0xFFFFFFFF); // White destructive
  static const Color darkDestructiveForegound = Color(
    0xFF000000,
  ); // Black text on destructive

  // Status colors (monochrome variations)
  static const Color success = Color(0xFF404040); // Dark gray for success
  static const Color warning = Color(0xFF666666); // Medium gray for warnings
  static const Color error = Color(0xFF000000); // Black for errors
  static const Color info = Color(0xFF808080); // Light gray for information

  // Gradient colors for monochrome theme
  static const Color gradientStart = Color(0xFF000000); // Black
  static const Color gradientEnd = Color(0xFF404040); // Dark gray
}
