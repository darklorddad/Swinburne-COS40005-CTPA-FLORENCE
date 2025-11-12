import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  SettingsProvider() {
    // No-op
  }

  /// Demo mode is permanently disabled.
  bool get isDemoMode => false;

  /// This is a no-op as demo mode is disabled.
  Future<void> setDemoMode(bool value) async {
    // Do nothing.
  }
}
