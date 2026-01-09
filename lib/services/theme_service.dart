
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService with ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeService() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.dark.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeMode.index);
    notifyListeners();
  }
}


/// Application Theme Data
class AppTheme {
  // Colores de la paleta
  static const Color primaryRed = Color(0xFFC62828);
  static const Color nightBlack = Color(0xFF0E0E0E);
  static const Color woodBrown = Color(0xFF8B3A2E);
  static const Color agedWhite = Color(0xFFE6E0D4);
  static const Color metalGrey = Color(0xFF6B6B6B);
  static const Color darkRed = Color(0xFF7A1F1F);
  static const Color silentGreen = Color(0xFF2E7D32);
  static const Color suspicionAmber = Color(0xFFFFB300);

  // Colores adicionales para estados
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color errorRed = Color(0xFFF44336);
  static const Color successGreen = Color(0xFF4CAF50);

  // Tema oscuro (principal para el juego)
  static ThemeData get darkTheme {
    const Color surfaceColor = Color(0xFF1A1A1A);
    const Color onSurfaceColor = agedWhite;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: woodBrown,
        surface: surfaceColor,
        error: errorRed,
        onPrimary: agedWhite,
        onSecondary: agedWhite,
        onSurface: onSurfaceColor,
        onError: agedWhite,
      ),

      // Scaffold
      scaffoldBackgroundColor: nightBlack,
      canvasColor: surfaceColor,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: nightBlack,
        foregroundColor: agedWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: agedWhite),
        titleTextStyle: TextStyle(
          color: agedWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        // Headlines
        displayLarge: TextStyle(
          color: agedWhite,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto',
        ),
        displayMedium: TextStyle(
          color: agedWhite,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          fontFamily: 'Roboto',
        ),
        displaySmall: TextStyle(
          color: agedWhite,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),

        // Titles
        titleLarge: TextStyle(
          color: agedWhite,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
        titleMedium: TextStyle(
          color: agedWhite,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        titleSmall: TextStyle(
          color: agedWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),

        // Body
        bodyLarge: TextStyle(
          color: agedWhite,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto',
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: agedWhite,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto',
          height: 1.4,
        ),
        bodySmall: TextStyle(
          color: metalGrey,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto',
        ),

        // Labels
        labelLarge: TextStyle(
          color: agedWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        labelMedium: TextStyle(
          color: agedWhite,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
        labelSmall: TextStyle(
          color: metalGrey,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
      ).apply(fontFamily: 'Roboto'),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: agedWhite,
          disabledBackgroundColor: metalGrey,
          disabledForegroundColor: agedWhite.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          shadowColor: primaryRed.withOpacity(0.3),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: woodBrown,
          side: const BorderSide(color: woodBrown, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: agedWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Roboto',
            decoration: TextDecoration.underline,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: metalGrey, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: const TextStyle(
          color: metalGrey,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          color: metalGrey,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(
          color: errorRed,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shadowColor: Colors.black54, // Sombra más definida para el tema oscuro
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: const TextStyle(
          color: agedWhite,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Roboto',
        ),
        contentTextStyle: const TextStyle(
          color: agedWhite,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          fontFamily: 'Roboto',
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: metalGrey,
        thickness: 1,
        space: 16,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceColor,
        actionTextColor: primaryRed,
        contentTextStyle: const TextStyle(
          color: agedWhite,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryRed,
        linearTrackColor: metalGrey,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryRed.withOpacity(0.2),
        secondarySelectedColor: primaryRed,
        disabledColor: metalGrey.withOpacity(0.3),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: metalGrey),
        ),
        labelStyle: const TextStyle(
          color: agedWhite,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          color: agedWhite,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        brightness: Brightness.dark,
      ),
    );
  }

  // Tema claro (opcional, para futuras expansiones)
  static ThemeData get lightTheme {
    const Color surfaceColor = Colors.white;
    const Color backgroundColor = Color(0xFFF8F8F8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: woodBrown,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        error: errorRed,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}
