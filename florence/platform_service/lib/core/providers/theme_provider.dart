import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme Notifier
/// Manages application theme state (light/dark mode)
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  /// Check if dark mode is active
  bool get isDarkMode => state == ThemeMode.dark;

  /// Toggle between light and dark mode
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  /// Set specific theme mode
  void setTheme(ThemeMode mode) {
    state = mode;
  }

  /// Set light theme
  void setLightTheme() {
    state = ThemeMode.light;
  }

  /// Set dark theme
  void setDarkTheme() {
    state = ThemeMode.dark;
  }
}

/// Global provider for the theme state
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
