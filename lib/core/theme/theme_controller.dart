import 'package:flutter/material.dart';

enum AppColorTheme { teal, red, brown, pink }

class ThemeState {
  final ThemeMode mode;
  final AppColorTheme colorTheme;

  const ThemeState({required this.mode, required this.colorTheme});

  ThemeState copyWith({ThemeMode? mode, AppColorTheme? colorTheme}) {
    return ThemeState(
      mode: mode ?? this.mode,
      colorTheme: colorTheme ?? this.colorTheme,
    );
  }
}

/// A simple controller to handle theme switching using value notification.
/// This avoids heavy state management libraries for this specific feature.
class ThemeController extends ValueNotifier<ThemeState> {
  // Singleton pattern for easy access
  static final ThemeController instance = ThemeController._();

  ThemeController._()
    : super(
        const ThemeState(
          mode: ThemeMode.system,
          colorTheme: AppColorTheme.teal,
        ),
      );

  /// Toggles between light and dark mode.
  /// If currently system, it defaults to toggling based on the platform brightness.
  void toggleTheme() {
    if (value.mode == ThemeMode.light) {
      value = value.copyWith(mode: ThemeMode.dark);
    } else {
      value = value.copyWith(mode: ThemeMode.light);
    }
  }

  /// Sets a specific theme mode
  void setTheme(ThemeMode mode) {
    value = value.copyWith(mode: mode);
  }

  /// Sets a specific color theme
  void setColorTheme(AppColorTheme theme) {
    value = value.copyWith(colorTheme: theme);
  }

  bool get isDark => value.mode == ThemeMode.dark;
}
