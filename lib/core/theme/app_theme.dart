import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9F6EE), // Warm Cream
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF781C2E), // Primary Burgundy
      primary: const Color(0xFF781C2E),
      secondary: const Color(0xFF8B2635), // Variation 1
      tertiary: const Color(0xFF9E2F3C), // Variation 2,
      surfaceTint: const Color(0xFFB13843), // Variation 3
      background: const Color(0xFFF9F6EE),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF9F6EE),
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF781C2E)),
      titleTextStyle: TextStyle(
        color: Color(0xFF781C2E),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x1A781C2E)), // 0.1 opacity
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF781C2E),
        foregroundColor: const Color(0xFFF9F6EE),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFFF9F6EE),
      indicatorColor: const Color(0x33781C2E), // ~0.2 opacity
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(color: Color(0xFF781C2E), fontWeight: FontWeight.w500),
      ),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: Color(0xFF781C2E));
        }
        return const IconThemeData(color: Color(0x80781C2E)); // 0.5 opacity
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF9F6EE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1A781C2E)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x1A781C2E)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF781C2E), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xCC781C2E)),
      prefixIconColor: const Color(0xFF781C2E),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF781C2E),
        side: const BorderSide(color: Color(0xFF781C2E)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF781C2E),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF781C2E), // Use Burgundy as seed even for dark mode
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
}
