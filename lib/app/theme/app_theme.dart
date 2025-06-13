import 'package:flutter/material.dart';

class AppTheme {
  static Color getRoleColor(String role) {
    switch (role) {
      case 'Owner':
        return Colors.blue;
      case 'Foreman':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  static Color getRoleLightColor(String role) {
    switch (role) {
      case 'Owner':
        return Colors.blue[50]!;
      case 'Foreman':
        return Colors.brown[50]!;
      default:
        return Colors.blue[50]!;
    }
  }

  static ThemeData getTheme(String role) {
    final primaryColor = getRoleColor(role);
    final backgroundColor = getRoleLightColor(role);

    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
