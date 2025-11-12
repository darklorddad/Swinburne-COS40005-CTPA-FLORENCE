import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDemoMode = true; // Default to demo mode on first launch
  static const String _demoModeKey = 'isDemoMode';

  SettingsProvider() {
    _loadSettings();
  }

  bool get isDemoMode => _isDemoMode;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDemoMode = prefs.getBool(_demoModeKey) ?? true;
    notifyListeners();
  }

  Future<void> setDemoMode(bool value) async {
    _isDemoMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_demoModeKey, value);
    notifyListeners();
  }
}
