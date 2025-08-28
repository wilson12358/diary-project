import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  AppThemeType _currentTheme = AppThemeType.orange;
  bool _isInitialized = false;
  
  AppThemeType get currentTheme => _currentTheme;
  bool get isInitialized => _isInitialized;
  
  ThemeService() {
    _loadTheme();
  }
  
  /// Load saved theme from SharedPreferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      _currentTheme = AppThemeType.values[themeIndex];
      AppColors.setTheme(_currentTheme);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
      // Keep default theme
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  /// Save theme to SharedPreferences
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _currentTheme.index);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }
  
  /// Change theme and notify listeners
  Future<void> changeTheme(AppThemeType newTheme) async {
    if (_currentTheme != newTheme) {
      _currentTheme = newTheme;
      AppColors.setTheme(newTheme);
      await _saveTheme();
      notifyListeners();
    }
  }
  
  /// Get all available themes
  List<AppThemeType> get availableThemes => AppThemeType.values;
  
  /// Get theme name
  String getThemeName(AppThemeType theme) => AppColors.getThemeName(theme);
  
  /// Get theme description
  String getThemeDescription(AppThemeType theme) => AppColors.getThemeDescription(theme);
  
  /// Get theme icon
  IconData getThemeIcon(AppThemeType theme) => AppColors.getThemeIcon(theme);
  
  /// Check if theme is currently selected
  bool isThemeSelected(AppThemeType theme) => _currentTheme == theme;
}
