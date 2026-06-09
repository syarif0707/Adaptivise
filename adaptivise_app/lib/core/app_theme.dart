import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB), // A professional tech blue
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class AppColors {
  // Consistent VARK Colors
  static const Color visual = Color(0xFF81C784); // Green (from your example)
  static const Color aural = Color(0xFFFFB74D); // Orange
  static const Color readWrite = Color(0xFFBA68C8); // Purple
  static const Color kinesthetic = Color(0xFF4FC3F7); // Blue (or change back to match example preference)
  
  // Alternative Kinesthetic to match your green pie chart:
  // static const Color kinesthetic = Color(0xFF81C784);
  // Then change Visual to something else, e.g., Red: Color(0xFFE57373)

  // Primary App Color (Teal/Dark Green)
  static const Color primary = Color(0xFF00796B); 
  static const Color background = Color(0xFFF5F7FA);

  static Color? get primaryTeal => null;
}