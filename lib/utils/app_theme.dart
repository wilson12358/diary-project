import 'package:flutter/material.dart';

// Theme enum for easy management
enum AppThemeType {
  orange,    // Current theme
  blue,      // Cool blue theme
  green,     // Nature green theme
  purple,    // Royal purple theme
  pink,      // Warm pink theme
  teal,      // Modern teal theme
}

class AppColors {
  // Theme color schemes
  static const Map<AppThemeType, Map<String, Color>> themeColors = {
    AppThemeType.orange: {
      'primary': Color(0xFFFCA032),      // #fca032 - Main orange
      'secondary': Color(0xFFFF8C42),    // #FF8C42 - Orange (more readable)
      'accent': Color(0xFFFC3B32),       // #fc3b32 - Red accent
      'primaryLight': Color(0xFFFFB366), // Lighter orange
      'primaryDark': Color(0xFFE68A00),  // Darker orange
      'secondaryLight': Color(0xFFFFA366), // Lighter orange
      'secondaryDark': Color(0xFFE67300),  // Darker orange
    },
    AppThemeType.blue: {
      'primary': Color(0xFF2196F3),      // #2196F3 - Material Blue
      'secondary': Color(0xFF64B5F6),    // #64B5F6 - Light Blue
      'accent': Color(0xFF1976D2),       // #1976D2 - Dark Blue
      'primaryLight': Color(0xFF90CAF9), // Lighter blue
      'primaryDark': Color(0xFF1565C0),  // Darker blue
      'secondaryLight': Color(0xFFBBDEFB), // Lighter blue
      'secondaryDark': Color(0xFF0D47A1),  // Darker blue
    },
    AppThemeType.green: {
      'primary': Color(0xFF4CAF50),      // #4CAF50 - Material Green
      'secondary': Color(0xFF81C784),    // #81C784 - Light Green
      'accent': Color(0xFF388E3C),       // #388E3C - Dark Green
      'primaryLight': Color(0xFFA5D6A7), // Lighter green
      'primaryDark': Color(0xFF2E7D32),  // Darker green
      'secondaryLight': Color(0xFFC8E6C9), // Lighter green
      'secondaryDark': Color(0xFF1B5E20),  // Darker green
    },
    AppThemeType.purple: {
      'primary': Color(0xFF9C27B0),      // #9C27B0 - Material Purple
      'secondary': Color(0xFFBA68C8),    // #BA68C8 - Light Purple
      'accent': Color(0xFF7B1FA2),       // #7B1FA2 - Dark Purple
      'primaryLight': Color(0xFFCE93D8), // Lighter purple
      'primaryDark': Color(0xFF6A1B9A),  // Darker purple
      'secondaryLight': Color(0xFFE1BEE7), // Lighter purple
      'secondaryDark': Color(0xFF4A148C),  // Darker purple
    },
    AppThemeType.pink: {
      'primary': Color(0xFFE91E63),      // #E91E63 - Material Pink
      'secondary': Color(0xFFF48FB1),    // #F48FB1 - Light Pink
      'accent': Color(0xFFC2185B),       // #C2185B - Dark Pink
      'primaryLight': Color(0xFFF8BBD9), // Lighter pink
      'primaryDark': Color(0xFFAD1457),  // Darker pink
      'secondaryLight': Color(0xFFFCE4EC), // Lighter pink
      'secondaryDark': Color(0xFF880E4F),  // Darker pink
    },
    AppThemeType.teal: {
      'primary': Color(0xFF009688),      // #009688 - Material Teal
      'secondary': Color(0xFF4DB6AC),    // #4DB6AC - Light Teal
      'accent': Color(0xFF00695C),       // #00695C - Dark Teal
      'primaryLight': Color(0xFF80CBC4), // Lighter teal
      'primaryDark': Color(0xFF004D40),  // Darker teal
      'secondaryLight': Color(0xFFB2DFDB), // Lighter teal
      'secondaryDark': Color(0xFF00251A),  // Darker teal
    },
  };

  // Current theme (defaults to orange)
  static AppThemeType _currentTheme = AppThemeType.orange;

  // Getters for current theme colors
  static Color get primaryColor => themeColors[_currentTheme]!['primary']!;
  static Color get secondaryColor => themeColors[_currentTheme]!['secondary']!;
  static Color get accentColor => themeColors[_currentTheme]!['accent']!;
  static Color get primaryLight => themeColors[_currentTheme]!['primaryLight']!;
  static Color get primaryDark => themeColors[_currentTheme]!['primaryDark']!;
  static Color get secondaryLight => themeColors[_currentTheme]!['secondaryLight']!;
  static Color get secondaryDark => themeColors[_currentTheme]!['secondaryDark']!;

  // Supporting colors (same for all themes)
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF424242);

  // Theme management
  static AppThemeType get currentTheme => _currentTheme;
  
  static void setTheme(AppThemeType theme) {
    _currentTheme = theme;
  }

  static String getThemeName(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.orange:
        return 'Orange Sunset';
      case AppThemeType.blue:
        return 'Ocean Blue';
      case AppThemeType.green:
        return 'Forest Green';
      case AppThemeType.purple:
        return 'Royal Purple';
      case AppThemeType.pink:
        return 'Cherry Blossom';
      case AppThemeType.teal:
        return 'Modern Teal';
    }
  }

  static String getThemeDescription(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.orange:
        return 'Warm and energetic orange theme';
      case AppThemeType.blue:
        return 'Calm and professional blue theme';
      case AppThemeType.green:
        return 'Fresh and natural green theme';
      case AppThemeType.purple:
        return 'Elegant and creative purple theme';
      case AppThemeType.pink:
        return 'Soft and romantic pink theme';
      case AppThemeType.teal:
        return 'Modern and sophisticated teal theme';
    }
  }

  static IconData getThemeIcon(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.orange:
        return Icons.wb_sunny;
      case AppThemeType.blue:
        return Icons.water_drop;
      case AppThemeType.green:
        return Icons.eco;
      case AppThemeType.purple:
        return Icons.auto_awesome;
      case AppThemeType.pink:
        return Icons.favorite;
      case AppThemeType.teal:
        return Icons.architecture;
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return getDynamicTheme(AppColors.currentTheme);
  }
  
  static ThemeData getDynamicTheme(AppThemeType themeType) {
    // Set the current theme in AppColors before creating ThemeData
    AppColors.setTheme(themeType);
    
    return ThemeData(
      primarySwatch: _createMaterialColor(AppColors.primaryColor),
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.secondaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
    );
  }

  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
