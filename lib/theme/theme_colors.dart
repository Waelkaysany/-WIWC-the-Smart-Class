import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extension on [BuildContext] to easily access theme-aware colors.
/// Use `context.surface` instead of `AppColors.surface` everywhere.
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get background     => isDark ? AppColors.background     : AppColorsLight.background;
  Color get surface        => isDark ? AppColors.surface         : AppColorsLight.surface;
  Color get surfaceLight   => isDark ? AppColors.surfaceLight    : AppColorsLight.surfaceLight;
  Color get textPrimary    => isDark ? AppColors.textPrimary     : AppColorsLight.textPrimary;
  Color get textSecondary  => isDark ? AppColors.textSecondary   : AppColorsLight.textSecondary;
  Color get textMuted      => isDark ? AppColors.textMuted       : AppColorsLight.textMuted;
  Color get cardBorder     => isDark ? AppColors.cardBorder      : AppColorsLight.cardBorder;
  Color get primary        => isDark ? AppColors.primary         : AppColorsLight.primary;
  Color get secondary      => isDark ? AppColors.secondary       : AppColorsLight.secondary;
  Color get error          => isDark ? AppColors.error           : AppColorsLight.error;
  Color get success        => isDark ? AppColors.success         : AppColorsLight.success;
  Color get warning        => isDark ? AppColors.warning         : AppColorsLight.warning;

  LinearGradient get surfaceGradient => isDark
      ? const LinearGradient(colors: [Color(0xFF1E2433), Color(0xFF161B26)], begin: Alignment.topLeft, end: Alignment.bottomRight)
      : const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FC)], begin: Alignment.topLeft, end: Alignment.bottomRight);

  LinearGradient get backgroundGradient => isDark
      ? const LinearGradient(colors: [Color(0xFF131620), AppColors.background], begin: Alignment.topCenter, end: Alignment.bottomCenter)
      : const LinearGradient(colors: [Color(0xFFF5F7FA), Color(0xFFEDF2F7)], begin: Alignment.topCenter, end: Alignment.bottomCenter);

  LinearGradient get statusCardGradient => isDark
      ? const LinearGradient(colors: [Color(0xFF1A2D45), Color(0xFF152238)], begin: Alignment.topLeft, end: Alignment.bottomRight)
      : const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFF0F4F8)], begin: Alignment.topLeft, end: Alignment.bottomRight);
}
