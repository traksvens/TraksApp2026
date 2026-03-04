import 'package:flutter/material.dart';

class AppColors {
  // Pure Black Theme (Dark)
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(
    0xFF141414,
  ); // Slightly elevated from pure black
  static const Color darkPrimary = Color(
    0xFFE5E5E5,
  ); // Softer white for easier reading
  static const Color darkAccent = Color(0xFF2DD4BF); // Teal 400
  static const Color darkTextPrimary = Color(0xFFF9FAFB); // Gray 50
  static const Color darkTextSecondary = Color(0xFFA1A1AA); // Zinc 400
  static const Color darkDivider = Color(0xFF27272A); // Zinc 800

  // Pure White Theme (Light)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF8FAFC); // Slate 50
  static const Color lightPrimary = Color(0xFF0D9488); // Teal 600
  static const Color lightAccent = Color(0xFF0F766E); // Teal 700
  static const Color lightTextPrimary = Colors.black;
  static const Color lightTextSecondary = Color(0xFF4B5563); // Gray 600
  static const Color lightDivider = Color(0xFFE5E7EB); // Gray 200

  // Semantic
  static const Color alertHigh = Color(0xFFEF4444); // Red 500
  static const Color alertMedium = Color(0xFFF97316); // Orange 500
  static const Color success = Color(0xFF10B981); // Emerald 500

  // Color Themes
  static const Color themeTeal = Color(0xFF14B8A6); // Teal 500
  static const Color themeRed = Color(0xFFDC2626); // Red 600
  static const Color themeBrown = Color(0xFF92400E); // Amber 800 (Brownish)
  static const Color themePink = Color(0xFFDB2777); // Pink 600
}
