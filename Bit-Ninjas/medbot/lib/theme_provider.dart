import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  void _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode_enabled') ?? false;
    notifyListeners();
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', _isDarkMode);
    notifyListeners();
  }

  void setTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', _isDarkMode);
    notifyListeners();
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      primaryColor: const Color(0xFF2563EB),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF2563EB), // Professional blue
        secondary: Color(0xFF10B981), // Emerald green
        surface: Colors.white,
        background: Color(0xFFF8F9FA),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1F2937),
        onBackground: Color(0xFF1F2937),
        error: Color(0xFFDC2626),
        onError: Colors.white,
        outline: Color(0xFFE5E7EB),
        surfaceVariant: Color(0xFFF3F4F6),
        onSurfaceVariant: Color(0xFF6B7280),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF2563EB)),
        actionsIconTheme: IconThemeData(color: Color(0xFF2563EB)),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF374151), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        titleLarge: TextStyle(
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleSmall: TextStyle(
          color: Color(0xFF374151),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF1F2937),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 2,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF2563EB);
          }
          return const Color(0xFFE5E7EB);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF2563EB).withOpacity(0.3);
          }
          return const Color(0xFFE5E7EB);
        }),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF3B82F6),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6), // Lighter blue for dark mode
        secondary: Color(0xFF10B981), // Emerald green
        surface: Color(0xFF1E293B),
        background: Color(0xFF0F172A),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF1F5F9),
        onBackground: Color(0xFFF1F5F9),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        outline: Color(0xFF475569),
        surfaceVariant: Color(0xFF334155),
        onSurfaceVariant: Color(0xFF94A3B8),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 2,
        titleTextStyle: TextStyle(
          color: Color(0xFFF1F5F9),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Color(0xFF3B82F6)),
        actionsIconTheme: IconThemeData(color: Color(0xFF3B82F6)),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E293B),
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE2E8F0), fontSize: 16),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        titleLarge: TextStyle(
          color: Color(0xFFF1F5F9),
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFF1F5F9),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleSmall: TextStyle(
          color: Color(0xFFE2E8F0),
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFFF1F5F9),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF3B82F6);
          }
          return const Color(0xFF64748B);
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const Color(0xFF3B82F6).withOpacity(0.3);
          }
          return const Color(0xFF475569);
        }),
      ),
    );
  }
}
