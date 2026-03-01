import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark mode colors
  static const background = Color(0xFF0F1115);
  static const surface = Color(0xFF1A1F2B);
  static const surfaceLight = Color(0xFF232938);
  static const primary = Color(0xFF3BE8B0);
  static const secondary = Color(0xFF8A7CFF);
  static const textPrimary = Color(0xFFF0F2F5);
  static const textSecondary = Color(0xFF9AA4B2);
  static const textMuted = Color(0xFF6B7280);
  static const error = Color(0xFFFF6B6B);
  static const success = Color(0xFF3BE8B0);
  static const warning = Color(0xFFFFD166);
  static const cardBorder = Color(0xFF2A3040);
}

class AppColorsLight {
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const surfaceLight = Color(0xFFF0F4F8);
  static const primary = Color(0xFF2DD4A0);
  static const secondary = Color(0xFF7C6EF0);
  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF718096);
  static const textMuted = Color(0xFFA0AEC0);
  static const error = Color(0xFFE53E3E);
  static const success = Color(0xFF38A169);
  static const warning = Color(0xFFD69E2E);
  static const cardBorder = Color(0xFFE2E8F0);
}

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        onPrimary: AppColors.background,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: _textTheme(textTheme, Brightness.dark),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 22,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsLight.background,
      colorScheme: const ColorScheme.light(
        surface: AppColorsLight.surface,
        primary: AppColorsLight.primary,
        secondary: AppColorsLight.secondary,
        error: AppColorsLight.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsLight.textPrimary,
        onError: Colors.white,
      ),
      textTheme: _textTheme(textTheme, Brightness.light),
      cardTheme: CardThemeData(
        color: AppColorsLight.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColorsLight.cardBorder, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.surface,
        selectedItemColor: AppColorsLight.primary,
        unselectedItemColor: AppColorsLight.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColorsLight.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColorsLight.textPrimary),
      ),
      iconTheme: const IconThemeData(
        color: AppColorsLight.textSecondary,
        size: 22,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Brightness brightness) {
    final primary = brightness == Brightness.dark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final secondary = brightness == Brightness.dark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final muted = brightness == Brightness.dark ? AppColors.textMuted : AppColorsLight.textMuted;

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        color: primary, fontWeight: FontWeight.bold, fontSize: 32,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary, fontWeight: FontWeight.bold, fontSize: 24,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary, fontWeight: FontWeight.w600, fontSize: 18,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primary, fontWeight: FontWeight.w500, fontSize: 16,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: primary, fontSize: 16),
      bodyMedium: base.bodyMedium?.copyWith(color: secondary, fontSize: 14),
      bodySmall: base.bodySmall?.copyWith(color: muted, fontSize: 12),
      labelLarge: base.labelLarge?.copyWith(
        color: secondary, fontWeight: FontWeight.w500, fontSize: 14,
      ),
      labelSmall: base.labelSmall?.copyWith(color: muted, fontSize: 11),
    );
  }
}
