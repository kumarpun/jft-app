import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark/system choice, persisted across launches.
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode mode = ThemeMode.system;

  Future<void> init() async {
    final v = (await SharedPreferences.getInstance()).getString(_key);
    mode = ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
    notifyListeners();
  }

  Future<void> set(ThemeMode m) async {
    if (m == mode) return;
    mode = m;
    notifyListeners();
    (await SharedPreferences.getInstance()).setString(_key, m.name);
  }
}

final themeController = ThemeController();
