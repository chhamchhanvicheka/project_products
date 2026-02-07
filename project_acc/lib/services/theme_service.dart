import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeSetting = prefs.getString(_themeKey) ?? 'light';
    _setThemeMode(themeSetting);
  }

  void setTheme(String theme) {
    print('🎨 ThemeService.setTheme() called with: $theme');
    _setThemeMode(theme);
    _saveTheme(theme);
  }

  void _setThemeMode(String theme) {
    switch (theme) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        print('🌙 Theme changed to DARK');
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        print('⚙️ Theme changed to SYSTEM');
        break;
      case 'light':
      default:
        _themeMode = ThemeMode.light;
        print('🌞 Theme changed to LIGHT');
        break;
    }
    print('📢 Notifying listeners...');
    notifyListeners();
  }

  Future<void> _saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.dark,
      ),
    );
  }
}
