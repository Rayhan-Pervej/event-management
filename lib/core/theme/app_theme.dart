import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF3F51B5),       // Vibrant Indigo
    onPrimary: Colors.white,          // Text/icons on primary
    secondary: Color(0xFFFF6F61),     // Coral/Salmon (energizing)
    onSecondary: Colors.white,        // Text/icons on secondary
    primaryContainer: Color(0xFFF3F4F6), // Light off-white background
    surface: Color(0xFFEDEDED),       // Slightly darker surface
    onSurface: Color(0xFF2C2C2C),     // Dark grey text
    error: Color(0xFFD32F2F),         // Strong red
    onError: Colors.white,
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: Color(0xFF2C2C2C),     // Consistent dark text
    displayColor: Color(0xFF2C2C2C),
  ),
);


  static final darkTheme = ThemeData(
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3F51B5),        // Same indigo as light theme
    onPrimary: Colors.white,           // Text/icons on primary
    secondary: Color(0xFFFF6F61),      // Same coral accent
    onSecondary: Colors.black,         // For contrast on lighter coral
    primaryContainer: Color(0xFF1E1E1E), // Dark background container
    surface: Color(0xFF2C2C2C),        // Slightly lighter surface (cards, sheets)
    onSurface: Color(0xFFE0E0E0),      // Light grey text
    error: Color(0xFFEF5350),          // Softer red for dark mode
    onError: Colors.black,
  ),
  textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: Color(0xFFE0E0E0),      // Light text for dark background
    displayColor: Color(0xFFE0E0E0),
  ),
);

}
