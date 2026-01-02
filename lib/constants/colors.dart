import 'package:flutter/material.dart';

/// App color scheme with Canadian theme
class AppColors {
  // Primary Canadian red theme
  static const Color primaryRed = Color(0xFFD52B1E); // Canadian flag red
  static const Color primaryRedLight = Color(0xFFFF5F52);
  static const Color primaryRedDark = Color(0xFF9C0000);

  // Background colors
  static const Color backgroundStart = Color(0xFFFFF5F5); // Very light red
  static const Color backgroundEnd = Color(0xFFFFFFFF);

  // Surface colors
  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);

  // Person badge colors - vibrant and distinguishable
  static const List<Color> personBadgeColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF009688), // Teal
    Color(0xFF3F51B5), // Indigo
    Color(0xFFFFC107), // Amber
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Tax category colors
  static const Map<String, Color> taxCategoryColors = {
    'alcohol': Color(0xFF8E24AA),
    'cannabis': Color(0xFF43A047),
    'tobacco': Color(0xFF6D4C41),
    'beverage': Color(0xFF0288D1),
    'accommodation': Color(0xFFFF7043),
    'fuel': Color(0xFF546E7A),
    'vaping': Color(0xFF90A4AE),
    'entertainment': Color(0xFFEC407A),
    'insurance': Color(0xFF5C6BC0),
    'ecoFees': Color(0xFF26A69A),
  };

  // Gradient for app background
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
    stops: [0.0, 0.3],
  );

  // Card shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Elevated card shadow
  static List<BoxShadow> get elevatedCardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Get color for a person by index
Color getPersonColor(int index) {
  return AppColors.personBadgeColors[index % AppColors.personBadgeColors.length];
}

/// Material 3 color scheme
ColorScheme getAppColorScheme(Brightness brightness) {
  return ColorScheme.fromSeed(
    seedColor: AppColors.primaryRed,
    brightness: brightness,
  );
}
