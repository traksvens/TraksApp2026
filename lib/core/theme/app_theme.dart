import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'theme_controller.dart';

class AppTheme {
  static Color _getPrimaryColor(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.red:
        return AppColors.themeRed;
      case AppColorTheme.brown:
        return AppColors.themeBrown;
      case AppColorTheme.pink:
        return AppColors.themePink;
      case AppColorTheme.teal:
        return AppColors.themeTeal;
    }
  }

  static ThemeData getDarkTheme(AppColorTheme colorTheme) {
    final primaryColor = _getPrimaryColor(colorTheme);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: primaryColor,
      dividerColor: AppColors.darkDivider,

      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkTextPrimary,
        onSurface: AppColors.darkTextPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.darkBackground,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.4,
        ),
        bodyMedium: TextStyle(
          color: AppColors.darkTextSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkBackground,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.darkTextSecondary.withOpacity(0.6),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData getLightTheme(AppColorTheme colorTheme) {
    final primaryColor = _getPrimaryColor(colorTheme);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: primaryColor,
      dividerColor: AppColors.lightDivider,

      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: AppColors.lightSurface,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightTextPrimary,
        onSurface: AppColors.lightTextPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.lightBackground,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
        bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
        titleLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),

      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: AppColors.lightTextSecondary.withOpacity(0.6),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}
