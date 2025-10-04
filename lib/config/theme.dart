import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AstroSynth Theme Configuration
/// Defines the visual appearance of the app with dark space theme

class AppTheme {
  // Color Palette - Space Theme
  static const Color primaryColor = Color(0xFF6C5CE7); // Cosmic Purple
  static const Color secondaryColor = Color(0xFF00B894); // Nebula Green
  static const Color accentColor = Color(0xFFFD79A8); // Star Pink
  static const Color warningColor = Color(0xFFFDCB6E); // Solar Yellow
  static const Color errorColor = Color(0xFFFF7675); // Red Giant

  static const Color darkBackground = Color(0xFF0D0D1E); // Deep Space
  static const Color cardBackground = Color(0xFF1A1A2E); // Dark Matter
  static const Color surfaceColor = Color(0xFF16213E); // Void

  static const Color textPrimary = Color(0xFFEEEEEE); // Starlight
  static const Color textSecondary = Color(0xFFB0B0C3); // Moonlight
  static const Color textMuted = Color(0xFF6C6C80); // Stardust

  // Habitability Score Colors
  static const Color habitableHigh = Color(0xFF00B894); // Green
  static const Color habitableMedium = Color(0xFFFDCB6E); // Yellow
  static const Color habitableLow = Color(0xFFFF7675); // Red
  static const Color habitableUnknown = Color(0xFF6C6C80); // Gray

  // Gradient Colors
  static const List<Color> spaceGradient = [
    Color(0xFF0D0D1E),
    Color(0xFF1A1A2E),
    Color(0xFF16213E),
  ];

  static const List<Color> nebulaGradient = [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFFD79A8),
  ];

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.25,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.orbitron(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textMuted,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: textSecondary),
        hintStyle: GoogleFonts.poppins(color: textMuted),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        selectedColor: primaryColor.withValues(alpha: 0.3),
        disabledColor: surfaceColor.withValues(alpha: 0.5),
        labelStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textPrimary, size: 24),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: textMuted.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Helper methods for gradients
  static LinearGradient get spaceBackgroundGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: spaceGradient,
    );
  }

  static LinearGradient get nebulaBackgroundGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: nebulaGradient,
    );
  }

  // Helper method to get habitability color
  static Color getHabitabilityColor(double? score) {
    if (score == null) return habitableUnknown;
    if (score >= 70) return habitableHigh;
    if (score >= 40) return habitableMedium;
    return habitableLow;
  }

  // Helper method to get discovery method color
  static Color getDiscoveryMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'transit':
        return primaryColor;
      case 'radial velocity':
        return secondaryColor;
      case 'microlensing':
        return accentColor;
      case 'direct imaging':
        return warningColor;
      default:
        return textMuted;
    }
  }
}
